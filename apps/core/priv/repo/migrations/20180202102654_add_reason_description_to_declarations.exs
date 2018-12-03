defmodule Core.Repo.Migrations.AddReasonDescriptionToDeclarations do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add :reason_description, :string
    end
  end
end
