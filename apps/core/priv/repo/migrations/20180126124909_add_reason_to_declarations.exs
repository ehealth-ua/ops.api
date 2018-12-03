defmodule Core.Repo.Migrations.AddReasonToDeclarations do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add :reason, :string
    end
  end
end
