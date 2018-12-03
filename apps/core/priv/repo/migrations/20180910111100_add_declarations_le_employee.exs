defmodule Core.Repo.Migrations.AddDeclarationsLegalEnityEmployeeIx do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("CREATE INDEX CONCURRENTLY IF NOT EXISTS
         declarations_legal_entity_employee_index ON DECLARATIONS (legal_entity_id, employee_id);")
  end
end
