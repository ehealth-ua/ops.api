defmodule Core.MedicationRequests do
  @moduledoc false

  use Core.Search
  alias Core.Declarations.Declaration
  alias Core.EventManager
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.MedicationRequest.DoctorSearch
  alias Core.MedicationRequest.QualifySearch
  alias Core.MedicationRequest.Search
  alias Core.MedicationRequests.MedicationRequest
  alias Core.Repo
  import Ecto.Changeset
  import Core.AuditLogs, only: [create_audit_logs: 1]

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, MedicationRequest)
  end

  def doctor_list(params) do
    %DoctorSearch{}
    |> changeset(params)
    |> doctor_search()
    |> @read_repo.paginate(params)
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
    |> join(:left, [mr], d in Declaration, on: d.person_id == mr.person_id and d.status == ^Declaration.status(:active))
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
          |> join(:inner, [mr], md in MedicationDispense, on: md.medication_request_id == mr.id)
          |> where([mr, md], md.status == ^MedicationDispense.status(:processed))

        :prequalify ->
          query
      end

    {:ok, @read_repo.all(query)}
  end

  defp filter_by_employees(query, []), do: query

  defp filter_by_employees(query, employee_ids) do
    where(query, [mr, d], mr.employee_id in ^employee_ids or d.employee_id in ^employee_ids)
  end

  def changeset(%Search{} = search, attrs) do
    # allow to search by all available fields
    cast(search, attrs, Search.__schema__(:fields))
  end

  def changeset(%DoctorSearch{} = search, attrs) do
    cast(search, attrs, DoctorSearch.__schema__(:fields))
  end

  def changeset(%MedicationRequest{} = medication_request, attrs) do
    cast(medication_request, attrs, MedicationRequest.__schema__(:fields))
  end

  def changeset(%QualifySearch{} = search, attrs) do
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

  def log_changes(_repo, %{medication_requests: {_, medication_requests}}) do
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

  def insert_events(_repo, multi, status, author_id) do
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
