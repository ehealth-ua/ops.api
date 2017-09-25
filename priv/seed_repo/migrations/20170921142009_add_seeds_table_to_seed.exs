defmodule OPS.SeedRepo.Migrations.AddSeedsTableToSeed do
  use Ecto.Migration

  def change do
    # TODO: add index (make sure only one record per day)
    create table(:seeds, primary_key: false) do
      add :hash, :bytea, null: false
      add :day, :date, null: false

      timestamps(updated_at: false, type: :utc_datetime)
    end
  end
end
