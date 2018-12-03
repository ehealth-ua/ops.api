defmodule Core.Repo.Migrations.AddOverlimit do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:declarations) do
      add(:overlimit, :boolean, null: true)
    end
  end
end
