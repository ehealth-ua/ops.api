defmodule Core.MedicationDispense.Details do
  @moduledoc false

  use Ecto.Schema
  alias Core.MedicationDispenses.MedicationDispense
  alias Ecto.UUID

  @derive {Jason.Encoder, except: ~w(__meta__ medication_dispense)a}

  schema "medication_dispense_details" do
    field(:medication_id, UUID)
    field(:medication_qty, :float)
    field(:sell_price, :float)
    field(:reimbursement_amount, :float)
    field(:medication_dispense_id, UUID)
    field(:sell_amount, :float)
    field(:discount_amount, :float)

    belongs_to(:medication_dispense, MedicationDispense, define_field: false)
  end
end
