defmodule Core.Repo.Migrations.AddSeedToDeclarations do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add :seed, :string
    end

    execute("update declarations set seed = '99bc78ba577a95a11f1a344d4d2ae55f2f857b98';")

    alter table(:declarations) do
      modify :seed, :string, null: false
    end
  end
end
