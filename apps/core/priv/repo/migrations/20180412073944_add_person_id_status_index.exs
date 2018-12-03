defmodule Core.Repo.Migrations.AddPersonIdStatusIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    create(index(:declarations, [:person_id, :status]))
  end
end
