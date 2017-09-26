defmodule OPS.BlockRepo.Migrations.ChangeBlocksStructure do
  use Ecto.Migration

  def up do
    alter table(:blocks, primary_key: false) do
      add :block_start, :utc_datetime, null: false
      add :block_end, :utc_datetime, null: false

      remove :day
    end
  end

  def down do
    alter table(:blocks, primary_key: false) do
      add :day, :date, null: false

      remove :block_start
      remove :block_end
    end
  end
end
