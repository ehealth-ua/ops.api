defmodule OPS.Web.MedicationDispenseView do
  @moduledoc false

  use OPS.Web, :view

  def render("show.json", %{medication_dispense: medication_dispense}) do
    Map.take(medication_dispense, ~w(
      id
      medication_request_id
      dispensed_at
      employee_id
      legal_entity_id
      division_id
      medical_program_id
      payment_id
      status
      inserted_at
      inserted_by
      updated_at
      updated_by
    )a)
  end
end
