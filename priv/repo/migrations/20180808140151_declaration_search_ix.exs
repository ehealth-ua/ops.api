defmodule OPS.Repo.Migrations.DeclarationSearchIx do
  use Ecto.Migration

  @disable_ddl_transaction true

  def up do
    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS
         declarations_legal_entity_is_active_status_inserted_at_index ON declarations(legal_entity_id, is_active, status, inserted_at desc)"
    )
  end

  def down do
    execute("DROP INDEX CONCURRENTLY IF  EXISTS
         declarations_legal_entity_is_active_status_inserted_at_index")
  end
end
