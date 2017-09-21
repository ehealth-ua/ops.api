defmodule OPS.Repo.Migrations.DropSeedsTableAndCleanup do
  use Ecto.Migration

  def up do
    alter table(:declarations) do
      remove :signed_data
    end

    drop table(:seeds)
  end

  def down do
    create table(:seeds) do
      add :hash, :bytea, null: false
      add :debug, :text, null: false
      add :inserted_at, :utc_datetime, null: false
    end

    alter table(:declarations) do
      add :signed_data, :bytea
      modify :seed, :string, null: false
    end
  end
end
