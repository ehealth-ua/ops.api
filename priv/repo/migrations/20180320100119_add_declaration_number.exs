defmodule OPS.Repo.Migrations.AddDeclarationNumber do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add(:declaration_number, :string)
    end
  end
end
