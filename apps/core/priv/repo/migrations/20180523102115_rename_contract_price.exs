defmodule Core.Repo.Migrations.RenameContractPrice do
  @moduledoc false

  use Ecto.Migration

  def change do
    rename(table(:contracts), :price, to: :nhs_contract_price)
  end
end
