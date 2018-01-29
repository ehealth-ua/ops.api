defmodule OPS.MedicationRequests do
  @moduledoc false

  alias OPS.MedicationRequests.MedicationRequest
  alias OPS.MedicationDispenses.MedicationDispense
  alias OPS.Repo
  alias OPS.MedicationRequest.Search
  alias OPS.Declarations.Declaration
  alias OPS.MedicationRequest.DoctorSearch
  alias OPS.MedicationRequest.QualifySearch
  import Ecto.Changeset
  import OPS.AuditLogs, only: [create_audit_logs: 1]
  alias Ecto.Multi
  alias OPS.EventManager
  use OPS.Search

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, MedicationRequest)
  end

  def doctor_list(params) do
    %DoctorSearch{}
    |> changeset(params)
    |> doctor_search()
    |> Repo.paginate(params)
  end

  def qualify_list(params) do
    %QualifySearch{}
    |> changeset(params)
    |> qualify_search()
  end

  def prequalify_list(params) do
    %QualifySearch{}
    |> changeset(params)
    |> prequalify_search()
  end

  def update(%MedicationRequest{status: old_status} = medication_request, attrs) do
    with {:ok, medication_request} <-
           medication_request
           |> changeset(attrs)
           |> Repo.update_and_log(Map.get(attrs, "updated_by")),
         author_id <- medication_request.updated_by,
         _ <- EventManager.insert_change_status(medication_request, old_status, medication_request.status, author_id) do
      {:ok, medication_request}
    end
  end

  def create(%{"medication_request" => mr}) do
    %MedicationRequest{}
    |> create_changeset(mr)
    |> Repo.insert_and_log(Map.get(mr, "employee_id"))
  end

  def get_search_query(entity, changes) do
    params =
      changes
      |> Map.drop(~w(status created_at)a)
      |> Map.to_list()

    entity
    |> where([mr], ^params)
    |> add_ilike_statuses(Map.get(changes, :status))
    |> add_created_at(Map.get(changes, :created_at))
    |> order_by([mr], mr.inserted_at)
  end

  defp add_ilike_statuses(query, nil), do: query

  defp add_ilike_statuses(query, values) do
    where(query, [mr], fragment("? ilike any (?)", mr.status, ^String.split(values, ",")))
  end

  defp add_created_at(query, nil), do: query

  defp add_created_at(query, value) do
    where(query, [mr], fragment("?::date = ?", mr.created_at, ^value))
  end

  defp doctor_search(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
    employee_ids =
      changeset
      |> get_change(:employee_id, "")
      |> String.split(",")
      |> Enum.filter(&(&1 != ""))

    filters =
      changes
      |> Map.drop(~w(employee_id created_from created_to)a)
      |> Map.to_list()

    MedicationRequest
    |> join(:left, [mr], d in Declaration, d.person_id == mr.person_id and d.status == ^Declaration.status(:active))
    |> where([mr], ^filters)
    |> filter_by_employees(employee_ids)
    |> add_created_at_doctor(Map.get(changes, :created_from), Map.get(changes, :created_to))
  end

  defp doctor_search(changeset), do: {:error, changeset}

  defp qualify_search(%Ecto.Changeset{valid?: true} = changeset) do
    qualify_query(changeset, :qualify)
  end

  defp qualify_search(changeset), do: {:error, changeset}

  defp prequalify_search(%Ecto.Changeset{valid?: true} = changeset) do
    qualify_query(changeset, :prequalify)
  end

  defp prequalify_search(changeset), do: {:error, changeset}

  def qualify_query(%Ecto.Changeset{valid?: true, changes: changes} = changeset, pre_or_qualify) do
    filters =
      changes
      |> Map.take(~w(person_id)a)
      |> Map.to_list()

    started_at = get_change(changeset, :started_at)
    ended_at = get_change(changeset, :ended_at)

    medication_request_statuses = [
      MedicationRequest.status(:active),
      MedicationRequest.status(:completed)
    ]

    query =
      MedicationRequest
      |> where([mr], ^filters)
      |> where([mr], mr.status in ^medication_request_statuses)
      |> where([mr], fragment("not (? > ? or ? < ?)", ^started_at, mr.ended_at, ^ended_at, mr.started_at))
      |> select([mr], mr.medication_id)

    query =
      case pre_or_qualify do
        :qualify ->
          query
          |> join(:inner, [mr], md in MedicationDispense, md.medication_request_id == mr.id)
          |> where([mr, md], md.status == ^MedicationDispense.status(:processed))

        :prequalify ->
          query
      end

    {:ok, Repo.all(query)}
  end

  defp filter_by_employees(query, []), do: query

  defp filter_by_employees(query, employee_ids) do
    where(query, [mr, d], mr.employee_id in ^employee_ids or d.employee_id in ^employee_ids)
  end

  defp changeset(%Search{} = search, attrs) do
    # allow to search by all available fields
    cast(search, attrs, Search.__schema__(:fields))
  end

  defp changeset(%DoctorSearch{} = search, attrs) do
    cast(search, attrs, DoctorSearch.__schema__(:fields))
  end

  defp changeset(%MedicationRequest{} = medication_request, attrs) do
    cast(medication_request, attrs, MedicationRequest.__schema__(:fields))
  end

  defp changeset(%QualifySearch{} = search, attrs) do
    search
    |> cast(attrs, QualifySearch.__schema__(:fields))
    |> validate_required(QualifySearch.__schema__(:fields))
  end

  defp create_changeset(%MedicationRequest{} = medication_request, attrs) do
    medication_request
    |> cast(attrs, MedicationRequest.__schema__(:fields))
    |> put_change(:status, MedicationRequest.status(:active))
    |> put_change(:is_active, true)
  end

  def terminate do
    query =
      MedicationRequest
      |> where([mr], mr.status == ^MedicationRequest.status(:active))
      |> where([mr], mr.ended_at <= ^Date.utc_today())

    new_status = MedicationRequest.status(:expired)
    author_id = Confex.fetch_env!(:ops, :system_user)

    updates = [
      status: new_status,
      updated_by: author_id,
      updated_at: DateTime.utc_now()
    ]

    Multi.new()
    |> Multi.update_all(:medication_requests, query, [set: updates], returning: [:id, :status, :updated_by])
    |> Multi.run(:insert_events, &insert_events(&1, new_status, author_id))
    |> Multi.run(:logged_terminations, &log_changes(&1))
    |> Repo.transaction()
  end

  defp log_changes(%{medication_requests: {_, medication_requests}}) do
    {_, changelog} =
      medication_requests
      |> Enum.map(fn mr ->
        %{
          actor_id: mr.updated_by,
          resource: "medication_requests",
          resource_id: mr.id,
          changeset: %{status: mr.status}
        }
      end)
      |> create_audit_logs()

    {:ok, changelog}
  end

  defp insert_events(multi, status, author_id) do
    {_, medication_requests} = multi.medication_requests

    Enum.each(medication_requests, fn medication_request ->
      EventManager.insert_change_status(medication_request, status, author_id)
    end)

    {:ok, medication_requests}
  end

  defp add_created_at_doctor(query, nil, nil), do: query

  defp add_created_at_doctor(query, created_from, nil) do
    where(query, [mr], fragment("?::date >= ?", mr.created_at, ^created_from))
  end

  defp add_created_at_doctor(query, nil, created_to) do
    where(query, [mr], fragment("?::date <= ?", mr.created_at, ^created_to))
  end

  defp add_created_at_doctor(query, created_from, created_to) do
    where(query, [mr], fragment("?::date BETWEEN ? AND ?", mr.created_at, ^created_from, ^created_to))
  end
end
