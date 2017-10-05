defmodule OPS.MedicationRequest.Schema do
  @moduledoc false

  use Ecto.Schema

  @derive {Poison.Encoder, except: [:__meta__]}

  @status_active "ACTIVE"
  @status_completed "COMPLETED"
  @status_rejected "REJECTED"
  @status_expired "EXPIRED"

  def status(:active), do: @status_active
  def status(:completed), do: @status_completed
  def status(:rejected), do: @status_rejected
  def status(:expired), do: @status_expired

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "medication_requests" do
    field :request_number, :string
    field :created_at, :date
    field :started_at, :date
    field :ended_at, :date
    field :dispense_valid_from, :date
    field :dispense_valid_to, :date
    field :person_id, Ecto.UUID
    field :employee_id, Ecto.UUID
    field :division_id, Ecto.UUID
    field :medication_id, Ecto.UUID
    field :medication_qty, :float
    field :status, :string
    field :is_active, :boolean
    field :rejected_at, :date
    field :rejected_by, Ecto.UUID
    field :reject_reason, :string
    field :medication_request_requests_id, Ecto.UUID
    field :medical_program_id, Ecto.UUID
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID
    field :verification_code, :string

    timestamps()
  end
end
