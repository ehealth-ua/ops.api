defmodule OPS.Declarations do
  @moduledoc """
  The boundary for the Declarations system
  """

  use OPS.Search
  import Ecto.{Query, Changeset}, warn: false
  alias Ecto.Multi
  alias OPS.Repo
  alias OPS.Block.API, as: BlockAPI
  alias OPS.Declarations.Declaration
  alias OPS.Declarations.DeclarationSearch
  alias OPS.API.IL
  import OPS.AuditLogs, only: [create_audit_logs: 1]
  require Logger

  def list_declarations(params) do
    %DeclarationSearch{}
    |> declaration_changeset(params)
    |> search(params, Declaration)
  end

  def get_declaration!(id), do: Repo.get!(Declaration, id)

  # TODO: Make more clearly getting created_by and updated_by parameters
  def create_declaration(attrs \\ %{}) do
    block = BlockAPI.get_latest()

    %Declaration{seed: block.hash}
    |> declaration_changeset(attrs)
    |> Repo.insert_and_log(Map.get(attrs, "created_by", Map.get(attrs, :created_by)))
  end

  def update_declaration(%Declaration{} = declaration, attrs) do
    updated_by = Map.get(attrs, "updated_by") || Map.get(attrs, :updated_by)

    declaration
    |> declaration_changeset(attrs)
    |> Repo.update_and_log(updated_by)
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

    declaration
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> validate_status_transition()
    |> validate_inclusion(:scope, ["family_doctor"])
    |> validate_inclusion(:status, Enum.map(
      ~w(
        active
        closed
        terminated
        rejected
        pending
      )a,
      &Declaration.status/1
    ))
  end

  defp declaration_changeset(%DeclarationSearch{} = declaration, attrs) do
    fields = DeclarationSearch.__schema__(:fields)

    cast(declaration, attrs, fields)
  end

  def create_declaration_with_termination_logic(%{"person_id" => person_id} = declaration_params) do
    query = Declaration
      |> where([d], d.person_id == ^person_id)
      |> where([d], d.status in ^[Declaration.status(:active), Declaration.status(:pending)])

    block = BlockAPI.get_latest()
    user_id = Map.get(declaration_params, "created_by")
    updates = [status: Declaration.status(:terminated), updated_by: user_id, updated_at: DateTime.utc_now()]

    Multi.new()
    |> Multi.update_all(:previous_declarations, query, [set: updates], returning: updated_fields_list(updates))
    |> Multi.insert(:new_declaration, declaration_changeset(%Declaration{seed: block.hash}, declaration_params))
    |> Multi.run(:log_declarations_update, &log_status_updates(&1.previous_declarations))
    |> Repo.transaction()
  end

  def approve_declarations do
    with {:ok, response} <- IL.get_global_parameters(),
         _ <- Logger.info("Global parameters: #{Poison.encode!(response)}"),
         parameters <- Map.fetch!(response, "data"),
         unit <- Map.fetch!(parameters, "verification_request_term_unit"),
         expiration <- Map.fetch!(parameters, "verification_request_expiration")
    do
      unit =
        unit
        |> String.downcase
        |> String.replace_trailing("s", "")
      do_approve_declarations(expiration, unit)
    end
  end

  defp do_approve_declarations(value, unit) do
    Logger.info("approve all declarations with inserted_at + #{value} #{unit} < now()")
    query =
      Declaration
      |> where([d], fragment("?::date < now()::date", datetime_add(d.inserted_at, ^value, ^unit)))
      |> where([d], d.status == ^Declaration.status(:pending))

    user_id = Confex.fetch_env!(:ops, :system_user)
    updates = [status: Declaration.status(:active), updated_by: user_id, updated_at: DateTime.utc_now()]

    Multi.new()
    |> Multi.update_all(:declarations, query, [set: updates], returning: updated_fields_list(updates))
    |> Multi.run(:logged_declarations, &log_status_updates(&1.declarations))
    |> Repo.transaction()
  end

  def terminate_declarations do
    query =
      Declaration
      |> where([d], fragment("?::date < now()::date", d.end_date))
      |> where([d], not d.status in ^[Declaration.status(:closed), Declaration.status(:terminated)])

    user_id = Confex.fetch_env!(:ops, :system_user)
    updates = [status: Declaration.status(:closed), updated_by: user_id, updated_at: DateTime.utc_now()]

    Multi.new()
    |> Multi.update_all(:declarations, query, [set: updates], returning: updated_fields_list(updates))
    |> Multi.run(:logged_terminations, &log_status_updates(&1.declarations))
    |> Repo.transaction()
  end
  def terminate_declarations(user_id, employee_id) do
    query =
      Declaration
      |> where([d], d.status in ^[Declaration.status(:active), Declaration.status(:pending)])
      |> where([d], d.employee_id == ^employee_id)

    updates = [status: Declaration.status(:terminated), updated_by: user_id, updated_at: DateTime.utc_now()]

    Multi.new
    |> Multi.update_all(:terminated_declarations, query, [set: updates], returning: updated_fields_list(updates))
    |> Multi.run(:logged_terminations, &log_status_updates(&1.terminated_declarations))
    |> Repo.transaction()
  end

  def terminate_person_declarations(user_id, person_id) do
    query = from d in Declaration, where: [person_id: ^person_id]

    updates = [status: "terminated", updated_by: user_id, updated_at: DateTime.utc_now()]

    Multi.new
    |> Multi.update_all(:terminated_declarations, query, [set: updates], returning: updated_fields_list(updates))
    |> Multi.run(:logged_terminations, &log_status_updates(&1.terminated_declarations))
    |> Repo.transaction()
  end

  def log_status_updates({_, declarations}) do
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

  def validate_status_transition(changeset) do
    from = changeset.data.status
    {_, to} = fetch_field(changeset, :status)

    valid_transitions = [
      {"active", "terminated"},
      {"active", "closed"},
      {"pending_verification", "active"},
      {"pending_verification", "rejected"}
    ]

    if {from, to} in valid_transitions || is_nil(from) do
      changeset
    else
      add_error(changeset, :status, "Incorrect status transition.")
    end
  end

  defp updated_fields_list(updates), do: [:id | Keyword.keys(updates)]
end
