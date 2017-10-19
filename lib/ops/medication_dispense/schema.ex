defmodule OPS.MedicationDispense.Schema do
  @moduledoc false

  use Ecto.Schema

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
    field :medication_request_id, Ecto.UUID
    field :dispensed_at, :date
    field :party_id, Ecto.UUID
    field :legal_entity_id, Ecto.UUID
    field :division_id, Ecto.UUID
    field :medical_program_id, Ecto.UUID
    field :payment_id, :string
    field :status, :string
    field :is_active, :boolean
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    has_many :details, OPS.MedicationDispense.Details, foreign_key: :medication_dispense_id
    belongs_to :medication_request, OPS.MedicationRequest.Schema, define_field: false

    timestamps(type: :utc_datetime)
  end
end
