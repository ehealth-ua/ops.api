defmodule OPS.Repo.Migrations.AddFieldsToMedicationDispenseDetails do
  use Ecto.Migration

  def change do
    alter table(:medication_dispense_details) do
      add :sell_amount, :float, null: false
      add :discount_amount, :float, null: false
    end
  end
end
