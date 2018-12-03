defmodule Core.Repo.Migrations.AddNewTables do
  use Ecto.Migration

  def change do
    alter table(:declarations, primary_key: false) do
      add :signed_data, :bytea
    end

    create table(:seeds, primary_key: false) do
      add :hash, :bytea, null: false
      add :debug, :text, null: false
      add :inserted_at, :utc_datetime, null: false
    end
  end
end
