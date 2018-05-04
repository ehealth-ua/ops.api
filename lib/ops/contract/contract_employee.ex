defmodule OPS.Contracts.ContractEmployee do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID
  alias OPS.Contracts.Contract

  schema "contract_employees" do
    field(:staff_units, :float)
    field(:declaration_limit, :integer)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)
    field(:employee_id, UUID)
    field(:division_id, UUID)

    belongs_to(:contract, Contract, type: UUID)

    timestamps()
  end
end
