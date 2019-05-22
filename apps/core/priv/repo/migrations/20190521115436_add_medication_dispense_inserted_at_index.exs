defmodule Core.Repo.Migrations.AddMedicationDispenseInsertedAtIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_dispenses_inserted_at_idx ON medication_dispenses (inserted_at);
    """)
  end
end
