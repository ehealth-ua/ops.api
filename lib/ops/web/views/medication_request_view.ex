defmodule OPS.Web.MedicationRequestView do
  @moduledoc false

  use OPS.Web, :view

  def render("index.json", %{medication_requests: medication_requests}) do
    render_many(medication_requests, __MODULE__, "show.json")
  end

  def render("show.json", %{medication_request: medication_request}) do
    Map.take(medication_request, ~w(
      id
      status
      reques_number
      created_at
      started_at
      ended_at
      dispense_valid_from
      dispense_valid_to
      person_id
      medication_id
      employee_id
      division_id
      legal_entity_id
    )a)
  end
end
