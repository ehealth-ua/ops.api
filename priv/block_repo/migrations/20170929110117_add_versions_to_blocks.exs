defmodule OPS.BlockRepo.Migrations.AddVersionsToBlocks do
  use Ecto.Migration

  def up do
    alter table(:blocks) do
      add :version, :string
    end

    execute("UPDATE blocks SET version = 'v1'")

    alter table(:blocks) do
      modify :version, :string, null: false
    end
  end

  def down do
    alter table(:blocks) do
      remove :version
    end
  end
end
