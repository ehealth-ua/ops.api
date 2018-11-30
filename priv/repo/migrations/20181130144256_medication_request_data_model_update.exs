defmodule OPS.Repo.Migrations.MedicationRequestDataModelUpdate do
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      add(:intent, :string, defalut: "order", null: false)
      add(:category, :string, defalut: "community", null: false)
      add(:context, :map)
      add(:dosage_instruction, {:array, :map})
    end
  end
end
