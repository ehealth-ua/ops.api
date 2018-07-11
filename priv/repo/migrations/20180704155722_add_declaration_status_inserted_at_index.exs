defmodule OPS.Repo.Migrations.AddDeclarationStatusInsertedAtIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    execute(
      "CREATE INDEX CONCURRENTLY IF NOT EXISTS declarations_status_inserted_at_index ON declarations(status, inserted_at desc)"
    )
  end
end
