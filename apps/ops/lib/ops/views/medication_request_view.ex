defmodule OPS.Web.MedicationRequestView do
  @moduledoc false

  use OPS.Web, :view

  def render("index.json", %{medication_requests: medication_requests}) do
    render_many(medication_requests, __MODULE__, "show.json")
  end

  def render("show.json", %{medication_request: medication_request}) do
    medication_request_fields = ~w(
      id
      request_number
      created_at
      started_at
      ended_at
      dispense_valid_from
      dispense_valid_to
      person_id
      employee_id
      division_id
      medication_id
      medication_qty
      status
      is_active
      rejected_at
      rejected_by
      reject_reason
      medication_request_requests_id
      medical_program_id
      inserted_by
      updated_by
      verification_code
      legal_entity_id
      intent
      category
      context
      dosage_instruction
      inserted_at
      updated_at
    )a

    Map.take(medication_request, medication_request_fields)
  end

  def render("qualify_list.json", %{ids: ids}) do
    ids
  end
end
