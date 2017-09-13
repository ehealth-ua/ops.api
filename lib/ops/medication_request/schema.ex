defmodule OPS.MedicationRequest.Schema do
  @moduledoc false

  use Ecto.Schema

  schema "medication_requests" do
    field :request_number, :string
    field :created_at, :date
    field :started_at, :date
    field :ended_at, :date
    field :dispense_valid_from, :date
    field :dispense_valid_to, :date
    field :person_id, Ecto.UUID
    field :employee_id, Ecto.UUID
    field :medication_id, Ecto.UUID
    field :medication_qty, :float
    field :note, :map
    field :dosage_instuction, :map
    field :status, :string
    field :is_active, :boolean
    field :recalled_at, :date
    field :recalled_by, Ecto.UUID
    field :recall_reason, :string
    field :medication_request_requests_id, Ecto.UUID
    field :medical_program_id, Ecto.UUID
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    timestamps()
  end
end
