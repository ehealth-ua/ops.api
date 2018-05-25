defmodule OPS.Contracts.ContractEmployee do
  @moduledoc false

  use Ecto.Schema
  alias Ecto.UUID
  alias OPS.Contracts.Contract
  import Ecto.Changeset

  @derive {Poison.Encoder, except: [:__meta__, :contract]}

  @primary_key {:id, :binary_id, autogenerate: true}

  @fields_required ~w(
    start_date
    employee_id
    division_id
    staff_units
    declaration_limit
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    end_date
  )a

  schema "contract_employees" do
    field(:employee_id, UUID)
    field(:staff_units, :float)
    field(:declaration_limit, :integer)
    field(:division_id, UUID)
    field(:start_date, :date)
    field(:end_date, :date)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    belongs_to(:contract, Contract, type: UUID)

    timestamps()
  end

  def changeset(%__MODULE__{} = contract_employee, attrs) do
    contract_employee
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end