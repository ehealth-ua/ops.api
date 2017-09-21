defmodule OPS.Web.MedicationDispenseView do
  @moduledoc false

  use OPS.Web, :view

  def render("index.json", %{medication_dispenses: medication_dispenses}) do
    render_many(medication_dispenses, __MODULE__, "show.json")
  end

  def render("show.json", %{medication_dispense: medication_dispense}) do
    medication_request = render_one(
      Map.get(medication_dispense, :medication_request),
      OPS.Web.MedicationRequestView,
      "show.json"
    )

    medication_dispense
    |> Map.take(~w(
      id
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
    |> Map.put("medication_request", medication_request)
  end
end
