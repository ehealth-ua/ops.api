defmodule OPS.Repo.Migrations.DeclarationIndexLegalEnityInsertedAtStatus do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute(
      " CREATE index CONCURRENTLY IF NOT EXISTS declarations_legal_entity_inserted_at_status_active_ix  ON declarations (legal_entity_id, inserted_at desc, status) where is_active;"
    )

    execute("DROP INDEX CONCURRENTLY IF  EXISTS
         declarations_legal_entity_inserted_at_index;")
  end
end
