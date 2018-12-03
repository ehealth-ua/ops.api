defmodule Core.Repo.Migrations.DropDeclarationsUnusedIndex do
  use Ecto.Migration

  @disable_ddl_transaction true

  def change do
    execute("DROP INDEX CONCURRENTLY IF  EXISTS
         declarations_person_id_index;")

    execute("DROP INDEX CONCURRENTLY IF  EXISTS
         declarations_legal_entity_id_is_active_index;")
  end
end
