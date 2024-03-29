defmodule Core.MedicationDispenses do
  @moduledoc false

  use Core.Search

  import Ecto.Changeset
  import Core.AuditLogs, only: [create_audit_logs: 1]

  alias Core.EventManager
  alias Core.MedicationDispense.Details
  alias Core.MedicationDispense.Search
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.MedicationRequests
  alias Core.Repo
  alias Scrivener.Page

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  @status_new MedicationDispense.status(:new)
  @status_processed MedicationDispense.status(:processed)
  @status_rejected MedicationDispense.status(:rejected)
  @status_expired MedicationDispense.status(:expired)

  @fields_required ~w(
    id
    medication_request_id
    dispensed_at
    party_id
    legal_entity_id
    division_id
    status
    is_active
    inserted_by
    updated_by
  )a

  @fields_optional ~w(medical_program_id payment_id payment_amount dispensed_by)a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search_medication_dispenses(params, MedicationDispense)
  end

  def get_search_query(entity, changes) do
    params = Map.drop(changes, ~w(dispensed_from dispensed_to)a)
    super(entity, params)
  end

  def create(attrs) do
    dispense_changeset = changeset(%MedicationDispense{}, attrs)
    details = Enum.map(Map.get(attrs, "dispense_details") || [], &details_changeset(%Details{}, &1))

    if dispense_changeset.valid? && Enum.all?(details, & &1.valid?) do
      Repo.transaction(fn ->
        inserted_by = Map.get(dispense_changeset.changes, :inserted_by)

        with {:ok, medication_dispense} <- Repo.insert_and_log(dispense_changeset, inserted_by) do
          Enum.each(details, fn item ->
            item = change(item, medication_dispense_id: medication_dispense.id)
            Repo.insert_and_log(item, inserted_by)
          end)

          Repo.preload(medication_dispense, ~w(medication_request details)a)
        end
      end)
    else
      case !dispense_changeset.valid? do
        true -> {:error, dispense_changeset}
        false -> {:error, Enum.find(details, &Kernel.!(&1.valid?))}
      end
    end
  end

  def update(%MedicationDispense{status: old_status} = medication_dispense, attrs) do
    author_id = Map.get(attrs, "updated_by") || Map.get(attrs, :updated_by)

    with changes <- changeset(medication_dispense, attrs),
         {:ok, medication_dispense} <-
           Repo.update_and_log(changes, author_id),
         _ <-
           EventManager.publish_change_status(
             medication_dispense,
             old_status,
             medication_dispense.status,
             medication_dispense.updated_by
           ) do
      {:ok, @read_repo.preload(medication_dispense, :medication_request, force: true)}
    end
  end

  def process(id, dispense_attrs, request_attrs) do
    with %Page{entries: [medication_dispense]} <- list(%{"id" => id}) do
      Repo.transaction(fn ->
        dispense_old_status = medication_dispense.status
        request_old_status = medication_dispense.medication_request.status

        with author_id <- Map.get(dispense_attrs, "updated_by") || Map.get(dispense_attrs, :updated_by),
             {:ok, medication_dispense} <-
               medication_dispense
               |> changeset(dispense_attrs)
               |> Repo.update_and_log(author_id),
             author_id <- Map.get(request_attrs, "updated_by") || Map.get(request_attrs, :updated_by),
             {:ok, medication_request} <-
               medication_dispense.medication_request
               |> MedicationRequests.changeset(request_attrs)
               |> Repo.update_and_log(author_id) do
          EventManager.publish_change_status(
            medication_dispense,
            dispense_old_status,
            medication_dispense.status,
            medication_dispense.updated_by
          )

          EventManager.publish_change_status(
            medication_request,
            request_old_status,
            medication_request.status,
            medication_request.updated_by
          )

          @read_repo.preload(medication_dispense, :medication_request, force: true)
        else
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end
  end

  def log_changes(_repo, %{medication_dispenses: {_, medication_dispenses}}) do
    {_, changelog} =
      medication_dispenses
      |> Enum.map(fn md ->
        %{
          actor_id: md.updated_by,
          resource: "medication_dispenses",
          resource_id: md.id,
          changeset: %{status: md.status}
        }
      end)
      |> create_audit_logs()

    {:ok, changelog}
  end

  defp changeset(%Search{} = search, attrs) do
    # allow to search by all available fields
    cast(search, attrs, Search.__schema__(:fields))
  end

  defp changeset(%MedicationDispense{} = medication_dispense, attrs) do
    medication_dispense
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
    |> validate_status_transition()
    |> validate_inclusion(
      :status,
      Enum.map(
        ~w(
        new
        processed
        rejected
        expired
      )a,
        &MedicationDispense.status/1
      )
    )
    |> unique_constraint(:medication_request_id, name: :medication_dispenses_medication_request_id_index)
  end

  defp validate_status_transition(changeset) do
    from = changeset.data.status
    {_, to} = fetch_field(changeset, :status)

    valid_transitions = [
      {nil, @status_new},
      {@status_new, @status_processed},
      {@status_new, @status_rejected},
      {@status_new, @status_expired}
    ]

    if {from, to} in valid_transitions do
      changeset
    else
      add_error(changeset, :status, "Incorrect status transition.")
    end
  end

  defp details_changeset(%Details{} = details, attrs) do
    fields = ~w(
      medication_id
      medication_qty
      sell_price
      reimbursement_amount
      sell_amount
      discount_amount
    )a

    details
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  def insert_events(_repo, multi, status, author_id) do
    {_, medication_dispenses} = multi.medication_dispenses

    Enum.each(medication_dispenses, fn medication_dispense ->
      EventManager.publish_change_status(medication_dispense, status, author_id)
    end)

    {:ok, medication_dispenses}
  end

  defp add_dispensed_at_query(query, nil, nil), do: query

  defp add_dispensed_at_query(query, dispensed_from, nil) do
    where(query, [md], md.dispensed_at >= ^dispensed_from)
  end

  defp add_dispensed_at_query(query, nil, dispensed_to) do
    where(query, [md], md.dispensed_at <= ^dispensed_to)
  end

  defp add_dispensed_at_query(query, dispensed_from, dispensed_to) do
    where(query, [md], fragment("? BETWEEN ? AND ?", md.dispensed_at, ^dispensed_from, ^dispensed_to))
  end

  defp search_medication_dispenses(%Ecto.Changeset{valid?: true, changes: changes}, search_params, entity) do
    entity
    |> get_search_query(changes)
    |> get_medication_dispenses_list(search_params, changes)
  end

  defp search_medication_dispenses(%Ecto.Changeset{valid?: false} = changeset, _search_params, _entity) do
    {:error, changeset}
  end

  defp get_medication_dispenses_list(query, search_params, changes) do
    dispensed_from = Map.get(changes, :dispensed_from)
    dispensed_to = Map.get(changes, :dispensed_to)

    entries_query =
      query
      |> join(:left, [md], mr in assoc(md, :medication_request))
      |> join(:left, [md, mr], d in assoc(md, :details))
      |> preload([md, mr, d], medication_request: mr, details: d)
      |> add_dispensed_at_query(dispensed_from, dispensed_to)

    count_query =
      query
      |> exclude(:order_by)
      |> add_dispensed_at_query(dispensed_from, dispensed_to)
      |> select([md], count(md.id))

    EctoPaginator.paginate(entries_query, count_query, @read_repo.paginator_options(search_params))
  end
end
