defmodule Core.Repo.Migrations.MedicationRequestLastExistingIndex do
  use Ecto.Migration

  def change do
    create(index(:medication_requests, [:person_id, :medication_id, :medical_program_id, :status]))
  end
end
