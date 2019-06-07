defmodule Core.MedicationRequests do
  @moduledoc false

  use Core.Search

  import Ecto.Changeset
  import Core.AuditLogs, only: [create_audit_logs: 1]

  alias Core.EventManager
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.MedicationRequest.DoctorSearch
  alias Core.MedicationRequest.QualifySearch
  alias Core.MedicationRequest.Search
  alias Core.MedicationRequests.MedicationRequest
  alias Core.Redis
  alias Core.Repo

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def list(params) do
    %{changes: search_params} = changeset(%Search{}, params)
    query = get_search_query(MedicationRequest, search_params)
    cache_key = get_cache_key(search_params)
    ttl = Confex.fetch_env!(:core, :cache)[:list_medication_requests_ttl]

    count_result = Redis.get_lazy(cache_key, ttl, fn -> @read_repo.aggregate(query, :count, :id) end)

    with {:ok, total_entries} <- count_result do
      options =
        params
        |> Map.take(["page", "page_size"])
        |> Map.put("options", total_entries: total_entries)
        |> @read_repo.paginator_options()

      query
      |> order_by([mr], mr.inserted_at)
      |> EctoPaginator.paginate(options)
    end
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
    author_id = Map.get(attrs, "updated_by") || Map.get(attrs, :updated_by)

    with changes <- changeset(medication_request, attrs),
         {:ok, medication_request} <- Repo.update_and_log(changes, author_id),
         _ <- EventManager.publish_change_status(medication_request, old_status, medication_request.status, author_id) do
      {:ok, medication_request}
    end
  end

  def create(%{"medication_request" => mr}) do
    mrr_id = mr["medication_request_requests_id"] || mr.medication_request_requests_id

    with nil <- get_unique_medication_request(mrr_id) do
      changes = create_changeset(%MedicationRequest{}, mr)
      Repo.insert_and_log(changes, get_change(changes, :employee_id))
    else
      %MedicationRequest{} = medication_request ->
        {:ok, medication_request}

      error ->
        error
    end
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
  end

  defp get_unique_medication_request(medication_request_requests_id) do
    MedicationRequest
    |> where([mr], mr.medication_request_requests_id == ^medication_request_requests_id)
    |> Repo.one()
  end

  defp add_ilike_statuses(query, nil), do: query

  defp add_ilike_statuses(query, values) do
    where(query, [mr], fragment("? ilike any (?)", mr.status, ^String.split(values, ",")))
  end

  defp add_created_at(query, nil), do: query

  defp add_created_at(query, value) do
    where(query, [mr], fragment("?::date = ?", mr.created_at, ^value))
  end

  defp doctor_search(%Ecto.Changeset{valid?: true, changes: changes}) do
    filters =
      changes
      |> Map.drop(~w(created_from created_to)a)
      |> Map.to_list()

    MedicationRequest
    |> where([mr], ^filters)
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
    |> unique_constraint(:id, name: :medication_requests_pkey)
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
      EventManager.publish_change_status(medication_request, status, author_id)
    end)

    {:ok, medication_requests}
  end

  def get_cache_key(params), do: Redis.create_cache_key("count_medication_requests", params)

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
