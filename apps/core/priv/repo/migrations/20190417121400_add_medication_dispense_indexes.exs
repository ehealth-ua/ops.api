defmodule Core.Repo.Migrations.ADDMedicationDispensesIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_dispenses_legal_entity_status_indx on medication_dispenses(legal_entity_id, status);
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_dispenses_division_indx on medication_dispenses(division_id);
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_dispenses_dispensed_at_indx on medication_dispenses(dispensed_at);
    """)
  end
end
