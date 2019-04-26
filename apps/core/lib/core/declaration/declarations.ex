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
  alias OPS.Redis
  alias Scrivener.Page

  import Core.AuditLogs, only: [create_audit_logs: 1, create_audit_log: 1]
  import Ecto.Changeset
  import Ecto.Query

  require Logger

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  @status_active Declaration.status(:active)
  @status_terminated Declaration.status(:terminated)
  @status_pending Declaration.status(:pending)

  def list_declarations(params) do
    %{changes: changes} = changeset = declaration_changeset(%DeclarationSearch{}, params)

    if Enum.all?(~w(legal_entity_id is_active status)a, &Map.has_key?(changes, &1)) and
         Enum.count(changes) == 3 do
      query = get_search_query(Declaration, changes)

      cache_key = "count_declarations_#{changes.legal_entity_id}#{changes.is_active}#{changes.status}"

      count =
        case Redis.get(cache_key) do
          {:ok, count} ->
            count

          _ ->
            count =
              query
              |> select([d], count(d.id))
              |> exclude(:order_by)
              |> @read_repo.one

            Redis.setex(cache_key, Confex.fetch_env!(:ops, :cache)[:list_declarations_ttl], count)
            count
        end

      page_number =
        case Integer.parse(Map.get(params, "page", "1")) do
          :error -> 1
          {value, _} -> value
        end

      page_size =
        case Integer.parse(Map.get(params, "page_size", "50")) do
          :error -> 50
          {value, _} -> min(value, 100)
        end

      query =
        query
        |> limit(^page_size)
        |> offset(^((page_number - 1) * page_size))

      entries = @read_repo.all(query)

      %Page{
        entries: entries,
        page_number: page_number,
        page_size: page_size,
        total_entries: count,
        total_pages: ceil(count / page_size)
      }
    else
      search(changeset, params, Declaration)
    end
  end

  def count_by_employee_ids(%{"ids" => employee_ids} = params) do
    {:ok,
     Declaration
     |> select([d], fragment("count(*)"))
     |> where([d], d.employee_id in ^employee_ids)
     |> where([d], d.status in ^[@status_active, @status_pending])
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
         _ <- EventManager.publish_change_status(declaration, old_status, declaration.status, declaration.updated_by) do
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

  def create_declaration_with_termination_logic(declaration_params) do
    block = BlockAPI.get_latest()

    with %Ecto.Changeset{valid?: true, changes: %{id: id, person_id: person_id, created_by: user_id}} =
           declaration_changeset <-
           declaration_changeset(%Declaration{seed: block.hash}, declaration_params),
         nil <- Repo.get(Declaration, id) do
      updates = [status: @status_terminated, updated_by: user_id, updated_at: DateTime.utc_now()]

      query =
        Declaration
        |> select([d], ^updated_fields_list(updates))
        |> where([d], d.person_id == ^person_id)
        |> where([d], d.status in ^[@status_active, @status_pending])

      Multi.new()
      |> Multi.update_all(:previous_declarations, query, set: updates)
      |> Multi.insert(:new_declaration, declaration_changeset, returning: true)
      |> Multi.run(:log_declarations_update, fn _repo, response ->
        {_, declarations} = response.previous_declarations
        log_status_updates(declarations, @status_terminated, user_id)
      end)
      |> Multi.run(:log_declaration_insert, &log_insert/2)
      |> Repo.transaction()
    else
      %Declaration{status: @status_active, is_active: true} = declaration ->
        {:ok, %{new_declaration: declaration}}

      %Declaration{} ->
        {:error, {:conflict, "Declaration inactive"}}

      error ->
        error
    end
  end

  def terminate_declaration(id, attrs) do
    attrs = Map.put(attrs, "status", @status_terminated)

    with %Declaration{} = declaration <- get_declaration!(id),
         updated_by <- Map.fetch!(attrs, "updated_by"),
         %Ecto.Changeset{valid?: true} = changeset <- terminate_changeset(declaration, attrs),
         {:ok, declaration} <- Repo.update_and_log(changeset, updated_by),
         {:ok, _} <- EventManager.publish_change_status(declaration, declaration.status, declaration.updated_by) do
      {:ok, declaration}
    end
  end

  def terminate_declarations(attrs, limit \\ 0) do
    query = where(Declaration, [d], d.status in ^[@status_active, @status_pending])

    query =
      if Map.has_key?(attrs, "person_id") do
        where(query, [d], d.person_id == ^Map.get(attrs, "person_id"))
      else
        where(query, [d], d.employee_id == ^Map.get(attrs, "employee_id"))
      end

    query =
      if limit != 0 do
        limit(query, ^limit)
      else
        query
      end

    user_id = Map.get(attrs, "actor_id")

    updates = [
      status: @status_terminated,
      reason: Map.get(attrs, "reason"),
      reason_description: Map.get(attrs, "reason_description"),
      updated_by: user_id,
      updated_at: DateTime.utc_now()
    ]

    query =
      Declaration
      |> select([d], ^updated_fields_list(updates))
      |> join(:inner, [d], s in subquery(query), on: s.id == d.id)

    {count, declarations} = Repo.update_all(query, set: updates)
    log_status_updates(declarations, @status_terminated, user_id)
    {:ok, declarations, count}
  end

  def chunk_terminate_declarations(attrs, limit), do: chunk_terminate_declarations({:ok, [], 1}, attrs, limit)

  def chunk_terminate_declarations({:ok, _, 0}, _attrs, _limit), do: :ok

  def chunk_terminate_declarations({:ok, _, _}, attrs, limit) do
    attrs
    |> terminate_declarations(limit)
    |> chunk_terminate_declarations(attrs, limit)
  end

  def get_person_ids([]), do: []

  def get_person_ids(employee_ids) when is_list(employee_ids) do
    Declaration
    |> select([d], d.person_id)
    |> where([d], d.status in ^[@status_active, @status_pending])
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
    query = select(query, [d], ^updated_fields_list(updates))

    Repo.transaction(fn ->
      {rows_updated, declarations} = Repo.update_all(query, set: updates)
      log_status_updates(declarations, status, user_id)
      rows_updated
    end)
  end

  def log_status_updates(declarations, status, user_id) do
    EventManager.publish_change_statuses(declarations, status, user_id)

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

  defp log_insert(_repo, %{new_declaration: %Declaration{} = declaration}) do
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
