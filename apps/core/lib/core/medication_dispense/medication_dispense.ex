defmodule Core.MedicationDispenses.MedicationDispense do
  @moduledoc false

  use Ecto.Schema
  alias Core.MedicationDispense.Details
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.UUID

  @status_new "NEW"
  @status_processed "PROCESSED"
  @status_rejected "REJECTED"
  @status_expired "EXPIRED"

  def status(:new), do: @status_new
  def status(:processed), do: @status_processed
  def status(:rejected), do: @status_rejected
  def status(:expired), do: @status_expired

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "medication_dispenses" do
    field(:medication_request_id, UUID)
    # Full name of worker who dispensed recipe
    field(:dispensed_by, :string)
    field(:dispensed_at, :date)
    field(:party_id, UUID)
    field(:legal_entity_id, UUID)
    field(:division_id, UUID)
    field(:medical_program_id, UUID)
    field(:payment_id, :string)
    field(:payment_amount, :float)
    field(:status, :string)
    field(:is_active, :boolean)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    has_many(:details, Details, foreign_key: :medication_dispense_id)
    belongs_to(:medication_request, MedicationRequest, define_field: false)

    timestamps(type: :utc_datetime)
  end
end
