defmodule Core.Repo.Migrations.ChangeDeclarationReasonDescriptionLength do
  use Ecto.Migration

  def change do
    alter table(:declarations) do
      modify :reason_description, :text
    end
  end
end
