defmodule Core.Repo.Migrations.AddMedicationIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_dispense_details_medication_dispense_id_indx on medication_dispense_details(medication_dispense_id);
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_requests_legal_entity_indx on medication_requests(legal_entity_id);
    """)

    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_requests_employee_indx on medication_requests(employee_id);
    """)
  end
end
