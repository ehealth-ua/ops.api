defmodule OPS.Repo.Migrations.DropContracts do
  @moduledoc false

  use Ecto.Migration

  def change do
    drop(table(:contract_employees))
    drop(table(:contract_divisions))
    drop(table(:contracts))
  end
end
