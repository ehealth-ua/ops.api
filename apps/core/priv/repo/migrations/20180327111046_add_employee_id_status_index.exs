defmodule Core.Repo.Migrations.AddEmployeeIdStatusIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    create(index(:declarations, [:employee_id, :status]))
  end
end
