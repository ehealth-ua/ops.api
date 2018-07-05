defmodule OPS.Repo.Migrations.AddDeclarationStatusInsertedAtIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  def change do
    create(index(:declarations, [:status, :inserted_at], concurrently: true))
  end
end
