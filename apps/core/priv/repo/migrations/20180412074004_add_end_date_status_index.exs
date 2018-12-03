defmodule Core.Repo.Migrations.AddEndDateStatusIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    create(index(:declarations, [:end_date, :status]))
  end
end
