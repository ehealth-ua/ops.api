defmodule OPS.BlockRepo.Migrations.AddInitialBlock do
  use Ecto.Migration

  def up do
    execute("
      INSERT INTO blocks (block_start, block_end, hash, inserted_at)
      VALUES ('1970-01-01 00:00:00', '1970-01-01 00:00:01', 'e9bc78ba577a95a11f1a344d4d2ae55f2f857b98', now())
    ")
  end

  def down do
    execute("DELETE FROM blocks WHERE hash = 'e9bc78ba577a95a11f1a344d4d2ae55f2f857b98'")
  end
end
