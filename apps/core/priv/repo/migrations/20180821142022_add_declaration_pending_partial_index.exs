defmodule Core.Repo.Migrations.AddDeclarationPartialPendingIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS declarations_pending_inserted_at_id_index ON declarations(inserted_at, id) WHERE  status = 'pending_verification'"
    )

    execute(
      "CREATE INDEX CONCURRENTLY declarations_legal_entity_status_active ON declarations (legal_entity_id , status) WHERE is_active;"
    )

    execute("DROP INDEX CONCURRENTLY IF EXISTS declarations_status_inserted_at_index")
  end
end
