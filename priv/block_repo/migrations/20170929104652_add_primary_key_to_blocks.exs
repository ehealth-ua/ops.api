defmodule OPS.BlockRepo.Migrations.AddPrimaryKeyToBlocks do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE blocks ADD id serial PRIMARY KEY")
  end

  def down do
    execute("ALTER TABLE blocks DROP COLUMN id")
  end
end
