defmodule OPS.BlockRepo.Migrations.AddSeedsTableToSeed do
  use Ecto.Migration

  def up do
    create table(:blocks, primary_key: false) do
      add :hash, :string, null: false
      add :block_start, :utc_datetime, null: false
      add :block_end, :utc_datetime, null: false

      timestamps(updated_at: false, type: :utc_datetime)
    end

    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")
  end

  def down do
    drop table(:blocks)

    execute("DROP EXTENSION IF EXISTS pgcrypto")
  end
end
