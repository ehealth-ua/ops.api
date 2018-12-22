defmodule Core.Repo.Migrations.MedicationRequestDispenseValidFieldsChangeToOptional do
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      modify(:dispense_valid_from, :date, null: true)
      modify(:dispense_valid_to, :date, null: true)
    end
  end
end
