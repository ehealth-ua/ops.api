defmodule Core.Declarations do
  @moduledoc """
  The boundary for the Declarations system
  """

  use Core.Search

  alias Core.Block.API, as: BlockAPI
  alias Core.Declarations.Declaration
  alias Core.Declarations.DeclarationSearch
  alias Core.EventManager
  alias Core.Repo
  alias Ecto.Multi

  import Core.AuditLogs, only: [create_audit_logs: 1, create_audit_log: 1]
  import Ecto.Changeset
  import Ecto.Query

  require Logger

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def list_declarations(params) do
    %DeclarationSearch{}
    |> declaration_changeset(params)
    |> search(params, Declaration)
  end

  def count_by_employee_ids(%{"ids" => employee_ids} = params) do
    {:ok,
     Declaration
     |> select([d], fragment("count(*)"))
     |> where([d], d.employee_id in ^employee_ids)
     |> where([d], d.status in [^Declaration.status(:active), ^Declaration.status(:pending)])
     |> filter_by_person_id(params)
     |> @read_repo.one!()}
  end

  def count_by_employee_ids(_), do: :error

  defp filter_by_person_id(query, %{"exclude_person_id" => exclude_person_id}) when not is_nil(exclude_person_id) do
    where(query, [d], d.person_id != ^exclude_person_id)
  end

  defp filter_by_person_id(query, _), do: query

  def get_declaration!(id), do: @read_repo.get!(Declaration, id)

  # TODO: Make more clearly getting created_by and updated_by parameters
  def create_declaration(attrs \\ %{}) do
    block = BlockAPI.get_latest()
    created_by = Map.get(attrs, "created_by") || Map.get(attrs, :created_by)

    %Declaration{seed: block.hash}
    |> declaration_changeset(attrs)
    |> Repo.insert_and_log(created_by)
  end

  def update_declaration(%Declaration{status: old_status} = declaration, attrs) do
    updated_by = Map.get(attrs, "updated_by") || Map.get(attrs, :updated_by)

    with {:ok, declaration} <-
           declaration
           |> declaration_changeset(attrs)
           |> Repo.update_and_log(updated_by),
         _ <- EventManager.insert_change_status(declaration, old_status, declaration.status, declaration.updated_by) do
      {:ok, declaration}
    end
  end

  def delete_declaration(%Declaration{} = declaration) do
    Repo.delete(declaration)
  end

  def change_declaration(%Declaration{} = declaration) do
    declaration_changeset(declaration, %{})
  end

  defp declaration_changeset(%Declaration{} = declaration, attrs) do
    fields = ~W(
      id
      employee_id
      person_id
      start_date
      end_date
      status
      signed_at
      created_by
      updated_by
      is_active
      scope
      division_id
      legal_entity_id
      declaration_request_id
      seed
    )a

    fields_optional = ~w(reason overlimit)a

    # declaration_number shouldn't be updated
    fields = if declaration.declaration_number, do: fields, else: fields ++ [:declaration_number]

    declaration
    |> cast(attrs, fields ++ fields_optional)
    |> validate_required(fields)
    |> validate_status_transition()
    |> validate_inclusion(:scope, ["family_doctor"])
    |> validate_inclusion(
      :status,
      Enum.map(
        ~w(
        active
        closed
        terminated
        rejected
        pending
      )a,
        &Declaration.status/1
      )
    )
    |> unique_constraint(:id, name: :declarations_pkey)
  end

  defp declaration_changeset(%DeclarationSearch{} = declaration, attrs) do
    fields = DeclarationSearch.__schema__(:fields)

    cast(declaration, attrs, fields)
  end

  defp terminate_changeset(%Declaration{} = declaration, attrs) do
    fields_required = ~w(status updated_by reason)a
    fields_optional = ~w(reason_description)a

    declaration
    |> cast(attrs, fields_required ++ fields_optional)
    |> validate_required(fields_required)
    |> validate_status_transition()
  end

  def create_declaration_with_termination_logic(%{"person_id" => person_id} = declaration_params) do
    query =
      Declaration
      |> where([d], d.person_id == ^person_id)
      |> where([d], d.status in ^[Declaration.status(:active), Declaration.status(:pending)])

    block = BlockAPI.get_latest()
    user_id = Map.get(declaration_params, "created_by")
    status = Declaration.status(:terminated)
    updates = [status: status, updated_by: user_id, updated_at: DateTime.utc_now()]

    Multi.new()
    |> Multi.update_all(:previous_declarations, query, [set: updates], returning: updated_fields_list(updates))
    |> Multi.insert(
      :new_declaration,
      declaration_changeset(%Declaration{seed: block.hash}, declaration_params),
      returning: true
    )
    |> Multi.run(:log_declarations_update, fn response ->
      {_, declarations} = response.previous_declarations
      log_status_updates(declarations, status, user_id)
    end)
    |> Multi.run(:log_declaration_insert, &log_insert(&1.new_declaration))
    |> Repo.transaction()
  end

  def terminate_declaration(id, attrs) do
    attrs = Map.put(attrs, "status", Declaration.status(:terminated))

    with %Declaration{} = declaration <- get_declaration!(id),
         updated_by <- Map.fetch!(attrs, "updated_by"),
         %Ecto.Changeset{valid?: true} = changeset <- terminate_changeset(declaration, attrs),
         {:ok, declaration} <- Repo.update_and_log(changeset, updated_by),
         {:ok, _} <- EventManager.insert_change_status(declaration, declaration.status, declaration.updated_by) do
      {:ok, declaration}
    end
  end

  def terminate_declarations(attrs) do
    query = where(Declaration, [d], d.status in ^[Declaration.status(:active), Declaration.status(:pending)])

    query =
      if Map.has_key?(attrs, "person_id") do
        where(query, [d], d.person_id == ^Map.get(attrs, "person_id"))
      else
        where(query, [d], d.employee_id == ^Map.get(attrs, "employee_id"))
      end

    status = Declaration.status(:terminated)
    user_id = Map.get(attrs, "actor_id")

    updates = [
      status: status,
      reason: Map.get(attrs, "reason"),
      reason_description: Map.get(attrs, "reason_description"),
      updated_by: user_id,
      updated_at: DateTime.utc_now()
    ]

    {_, declarations} = Repo.update_all(query, [set: updates], returning: updated_fields_list(updates))

    log_status_updates(declarations, status, user_id)
    {:ok, declarations}
  end

  def get_person_ids([]), do: []

  def get_person_ids(employee_ids) when is_list(employee_ids) do
    Declaration
    |> select([d], d.person_id)
    |> where([d], d.status in ^[Declaration.status(:active), Declaration.status(:pending)])
    |> where([d], d.employee_id in ^employee_ids)
    |> @read_repo.all()
  end

  def validate_status_transition(changeset) do
    from = changeset.data.status
    {_, to} = fetch_field(changeset, :status)

    valid_transitions = [
      {"active", "terminated"},
      {"active", "closed"},
      {"pending_verification", "active"},
      {"pending_verification", "rejected"},
      {"pending_verification", "terminated"}
    ]

    if {from, to} in valid_transitions || is_nil(from) do
      changeset
    else
      add_error(changeset, :status, "Incorrect status transition.")
    end
  end

  def update_rows(query, status: status, updated_by: user_id, updated_at: updated_at) do
    updates = [status: status, updated_by: user_id, updated_at: updated_at]

    Repo.transaction(fn ->
      {rows_updated, declarations} = Repo.update_all(query, [set: updates], returning: updated_fields_list(updates))
      log_status_updates(declarations, status, user_id)
      rows_updated
    end)
  end

  def log_status_updates(declarations, status, user_id) do
    EventManager.insert_change_statuses(declarations, status, user_id)

    {_, changelog} =
      declarations
      |> Enum.map(fn decl ->
        %{
          actor_id: decl.updated_by,
          resource: "declarations",
          resource_id: decl.id,
          changeset: %{status: decl.status}
        }
      end)
      |> create_audit_logs()

    {:ok, changelog}
  end

  def updated_fields_list(updates), do: [:id | Keyword.keys(updates)]

  defp log_insert(%Declaration{} = declaration) do
    changes = %{
      actor_id: declaration.created_by,
      resource: "declarations",
      resource_id: declaration.id,
      changeset: sanitize_changeset(declaration)
    }

    create_audit_log(changes)
    {:ok, declaration}
  end

  defp sanitize_changeset(declaration) do
    declaration
    |> Map.from_struct()
    |> Map.drop([:__meta__, :inserted_at, :updated_at])
  end
end
