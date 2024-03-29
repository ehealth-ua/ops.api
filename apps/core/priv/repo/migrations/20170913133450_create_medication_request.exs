defmodule Core.Repo.Migrations.CreateMedicationRequest do
  use Ecto.Migration

  def change do
    create table(:medication_requests, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :request_number, :string, null: false
      add :created_at, :date, null: false
      add :started_at, :date, null: false
      add :ended_at, :date, null: false
      add :dispense_valid_from, :date, null: false
      add :dispense_valid_to, :date, null: false
      add :person_id, :uuid, null: false
      add :employee_id, :uuid, null: false
      add :medication_id, :uuid, null: false
      add :medication_qty, :float, null: false
      add :note, :map
      add :dosage_instuction, :map
      add :status, :string, null: false
      add :is_active, :boolean, null: false
      add :recalled_at, :date
      add :recalled_by, :uuid
      add :recall_reason, :string
      add :medication_request_requests_id, :uuid, null: false
      add :medical_program_id, :uuid
      add :inserted_by, :uuid
      add :updated_by, :uuid

      timestamps()
    end
  end
end
