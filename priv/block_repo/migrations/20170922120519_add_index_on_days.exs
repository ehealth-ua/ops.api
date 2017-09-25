defmodule OPS.BlockRepo.Migrations.AddIndexOnDays do
  use Ecto.Migration

  def up do
    execute("CREATE UNIQUE INDEX days_idx ON blocks (date(day))")
  end

  def down do
    execute("DROP INDEX days_idx")
  end
end
