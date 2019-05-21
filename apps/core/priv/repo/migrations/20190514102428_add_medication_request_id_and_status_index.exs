defmodule Core.Repo.Migrations.AddMedicationRequestIdAndStatusIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS medication_dispenses_mr_id_status_idx ON medication_dispenses USING btree (medication_request_id, status);
    """)
  end
end
