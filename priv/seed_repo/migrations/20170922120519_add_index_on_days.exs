defmodule OPS.SeedRepo.Migrations.AddIndexOnDays do
  use Ecto.Migration

  def up do
    execute("CREATE UNIQUE INDEX days_idx ON seeds (date(inserted_at))");
  end

  def down do
    execute("DROP INDEX days_idx")
  end
end
