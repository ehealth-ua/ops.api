defmodule OPS.Repo.Migrations.AddDivisionIdToMedicationRequests do
  use Ecto.Migration

  def change do
    alter table(:medication_requests) do
      add :division_id, :uuid, null: false
    end
  end
end
