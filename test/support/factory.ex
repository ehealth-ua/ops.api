defmodule OPS.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: OPS.Repo

  alias OPS.Declarations.Declaration
  alias OPS.MedicationDispense.Schema, as: MedicationDispense
  alias OPS.MedicationRequest.Schema, as: MedicationRequest
  alias OPS.MedicationDispense.Details

  def declaration_factory do
    day = 60 * 60 * 24
    start_date = NaiveDateTime.utc_now() |> NaiveDateTime.add(-10 * day, :seconds)
    end_date = NaiveDateTime.add(start_date, day, :seconds)
    %Declaration{
      id: Ecto.UUID.generate(),
      declaration_request_id: Ecto.UUID.generate,
      start_date: start_date,
      end_date: end_date,
      status: Declaration.status(:active),
      signed_at: start_date,
      created_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      employee_id: Ecto.UUID.generate,
      person_id: Ecto.UUID.generate,
      division_id: Ecto.UUID.generate,
      legal_entity_id: Ecto.UUID.generate,
      is_active: true,
      scope: "",
      seed: "some seed"
    }
  end

  def medication_dispense_factory do
    %MedicationDispense{
      id: Ecto.UUID.generate(),
      status: MedicationDispense.status(:new),
      inserted_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      is_active: true,
      dispensed_at: to_string(Date.utc_today),
      party_id: Ecto.UUID.generate(),
      legal_entity_id: Ecto.UUID.generate(),
      payment_id: Ecto.UUID.generate(),
      division_id: Ecto.UUID.generate(),
      medical_program_id: Ecto.UUID.generate(),
      medication_request: build(:medication_request),
    }
  end

  def medication_request_factory do
    %MedicationRequest{
      id: Ecto.UUID.generate(),
      status: MedicationRequest.status(:active),
      inserted_by: Ecto.UUID.generate,
      updated_by: Ecto.UUID.generate,
      is_active: true,
      person_id: Ecto.UUID.generate(),
      employee_id: Ecto.UUID.generate(),
      division_id: Ecto.UUID.generate(),
      medication_id: Ecto.UUID.generate(),
      created_at: NaiveDateTime.utc_now(),
      started_at: NaiveDateTime.utc_now(),
      ended_at: NaiveDateTime.utc_now(),
      dispense_valid_from: Date.utc_today(),
      dispense_valid_to: Date.utc_today(),
      medication_qty: 0,
      medication_request_requests_id: Ecto.UUID.generate(),
      request_number: ""
    }
  end

  def medication_dispense_details_factory do
    %Details{
      medication_id: Ecto.UUID.generate(),
      medication_qty: 10,
      sell_price: 150,
      reimbursement_amount: 100,
      medication_dispense_id: Ecto.UUID.generate(),
      sell_amount: 30,
      discount_amount: 0
    }
  end
end
