defmodule Core.MedicationRequests.MedicationRequest do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID

  @derive {Jason.Encoder, except: [:__meta__]}

  @status_active "ACTIVE"
  @status_completed "COMPLETED"
  @status_rejected "REJECTED"
  @status_expired "EXPIRED"

  @intent_order "order"
  @intent_plan "plan"

  def status(:active), do: @status_active
  def status(:completed), do: @status_completed
  def status(:rejected), do: @status_rejected
  def status(:expired), do: @status_expired

  def intent(:order), do: @intent_order
  def intent(:plan), do: @intent_plan

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "medication_requests" do
    field(:request_number, :string)
    field(:created_at, :date)
    field(:started_at, :date)
    field(:ended_at, :date)
    field(:dispense_valid_from, :date)
    field(:dispense_valid_to, :date)
    field(:person_id, UUID)
    field(:employee_id, UUID)
    field(:division_id, UUID)
    field(:medication_id, UUID)
    field(:medication_qty, :float)
    field(:status, :string)
    field(:is_active, :boolean)
    field(:rejected_at, :date)
    field(:rejected_by, UUID)
    field(:reject_reason, :string)
    field(:medication_request_requests_id, UUID)
    field(:medical_program_id, UUID)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)
    field(:verification_code, :string)
    field(:legal_entity_id, UUID)
    field(:intent, :string, default: "order", null: false)
    field(:category, :string, default: "community", null: false)
    field(:context, :map)
    field(:dosage_instruction, {:array, :map})

    timestamps(type: :utc_datetime)
  end
end
