defmodule OPS.MedicationDispenses do
  @moduledoc false

  alias OPS.MedicationDispense.Schema, as: MedicationDispense
  alias OPS.MedicationDispense.Details
  alias OPS.Repo
  alias OPS.MedicationDispense.Search
  alias Ecto.Multi
  import Ecto.Changeset
  use OPS.Search

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
    medical_program_id
    status
    is_active
    inserted_by
    updated_by
  )a

  @fields_optional ~w(payment_id)a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, MedicationDispense)
  end

  def get_search_query(entity, changes) do
    entity
    |> super(changes)
    |> join(:left, [md], mr in assoc(md, :medication_request))
    |> join(:left, [md, mr], d in assoc(md, :details))
    |> preload([md, mr, d], [medication_request: mr, details: d])
  end

  def create(attrs) do
    dispense_changeset = changeset(%MedicationDispense{}, attrs)
    details = Enum.map(Map.get(attrs, "dispense_details") || [], &details_changeset(%Details{}, &1))

    if dispense_changeset.valid? && Enum.all?(details, & &1.valid?) do
      Repo.transaction fn ->
        inserted_by = Map.get(attrs, "inserted_by")
        with {:ok, medication_dispense} <- Repo.insert_and_log(dispense_changeset, inserted_by),
             _ <- Enum.map(details, fn item ->
                item = change(item, medication_dispense_id: medication_dispense.id)
                Repo.insert(item)
             end)
        do
          Repo.preload(medication_dispense, ~w(medication_request details)a)
        end
      end
    else
      case !dispense_changeset.valid? do
        true -> {:error, dispense_changeset}
        false -> {:error, Enum.find(details, & Kernel.!(&1.valid?))}
      end
    end
  end

  def update(medication_dispense, attrs) do
    with {:ok, medication_dispense} <- medication_dispense
                                       |> changeset(attrs)
                                       |> Repo.update_and_log(Map.get(attrs, "updated_by"))
    do
      {:ok, Repo.preload(medication_dispense, :medication_request, force: true)}
    end
  end

  def terminate(expiration) do
    query =
      MedicationDispense
      |> where([md], md.status == ^MedicationDispense.status(:new))
      |> where([md], md.inserted_at < datetime_add(^NaiveDateTime.utc_now, ^-expiration, "minute"))

    Multi.new()
    |> Multi.update_all(:medication_dispenses, query, set: [
      status: MedicationDispense.status(:expired),
      updated_at: NaiveDateTime.utc_now()
    ])
    |> Repo.transaction()
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
    |> validate_inclusion(:status, Enum.map(
      ~w(
        new
        processed
        rejected
        expired
      )a,
      &MedicationDispense.status/1
    ))
  end

  defp validate_status_transition(changeset) do
    from = changeset.data.status
    {_, to} = fetch_field(changeset, :status)

    valid_transitions = [
      {nil, @status_new},
      {@status_new, @status_processed},
      {@status_new, @status_rejected},
      {@status_new, @status_expired},
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
end
