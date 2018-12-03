defmodule Core.Repo.Migrations.SetDeclarationNumber do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("UPDATE declarations SET declaration_number = id")

    alter table(:declarations) do
      modify(:declaration_number, :string, null: false)
    end

    create(unique_index(:declarations, [:declaration_number]))
  end
end
