defmodule OPS.MedicationDispenses do
  @moduledoc false

  alias OPS.MedicationDispense.Schema, as: MedicationDispense
  alias OPS.MedicationDispense.Details
  alias OPS.Repo
  import Ecto.Changeset

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
    payment_id
    status
    is_active
    inserted_by
    updated_by
  )a

  @fields_optional ~w()a

  def get_medication_dispense!(id) do
    Repo.get!(MedicationDispense, id)
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
          medication_dispense
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
    medication_dispense
    |> changeset(attrs)
    |> Repo.update_and_log(Map.get(attrs, "updated_by"))
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

  def details_changeset(%Details{} = details, attrs) do
    fields = ~w(medication_id medication_qty sell_price reimbursement_amount)a

    details
    |> cast(attrs, fields)
    |> validate_required(fields)
  end
end
