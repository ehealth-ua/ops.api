defmodule Core.BlockRepo.Migrations.AddSeedsTableToSeed do
  use Ecto.Migration

  def up do
    create table(:blocks, primary_key: false) do
      add :hash, :string, null: false
      add :block_start, :utc_datetime_usec, null: false
      add :block_end, :utc_datetime_usec, null: false

      timestamps(updated_at: false, type: :utc_datetime_usec)
    end

    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")
  end

  def down do
    drop table(:blocks)

    execute("DROP EXTENSION IF EXISTS pgcrypto")
  end
end
