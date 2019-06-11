defmodule Core.Repo.Migrations.AddProgramMedicationIdToMedicationDispenseDetails do
  use Ecto.Migration

  def change do
    alter table(:medication_dispense_details) do
      add(:program_medication_id, :uuid)
    end
  end
end
