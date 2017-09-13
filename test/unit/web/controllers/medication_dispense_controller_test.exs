defmodule OPS.Web.MedicationDispenseControllerTest do
  use OPS.Web.ConnCase

  alias OPS.MedicationDispense.Schema, as: MedicationDispense

  @create_attrs %{
    id: Ecto.UUID.generate(),
    medication_request_id: Ecto.UUID.generate(),
    dispensed_at: "2017-08-17",
    party_id: Ecto.UUID.generate(),
    legal_entity_id: Ecto.UUID.generate(),
    payment_id: Ecto.UUID.generate(),
    employee_id: Ecto.UUID.generate(),
    division_id: Ecto.UUID.generate(),
    medical_program_id: Ecto.UUID.generate(),
    status: MedicationDispense.status(:new),
    is_active: true,
    inserted_by: Ecto.UUID.generate(),
    updated_by: Ecto.UUID.generate(),
    dispense_details: [
      %{
        medication_id: Ecto.UUID.generate(),
        medication_qty: 10,
        sell_price: 18.65,
        reimbursement_amount: 0,
      }
    ]
  }

  @update_attrs %{
    medication_request_id: Ecto.UUID.generate(),
    party_id: Ecto.UUID.generate(),
    dispensed_at: "2017-08-01",
    status: MedicationDispense.status(:rejected),
    inserted_by: Ecto.UUID.generate(),
    updated_by: Ecto.UUID.generate(),
    is_active: false,
    legal_entity_id: Ecto.UUID.generate(),
    division_id: Ecto.UUID.generate(),
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "creates medication dispense when data is valid", %{conn: conn} do
    conn = post conn, medication_dispense_path(conn, :create), medication_dispense: @create_attrs
    resp = json_response(conn, 201)["data"]

    medication_request_id = @create_attrs.medication_request_id
    division_id = @create_attrs.division_id
    legal_entity_id = @create_attrs.legal_entity_id
    status = MedicationDispense.status(:new)
    inserted_by = @create_attrs.inserted_by
    updated_by = @create_attrs.updated_by

    assert %{
      "id" => _id,
      "medication_request_id" => ^medication_request_id,
      "division_id" => ^division_id,
      "legal_entity_id" => ^legal_entity_id,
      "dispensed_at" => "2017-08-17",
      "status" => ^status,
      "inserted_by" => ^inserted_by,
      "updated_by" => ^updated_by,
    } = resp
  end

  test "create medication dispense with invalid params", %{conn: conn} do
    conn = post conn, medication_dispense_path(conn, :create), medication_dispense: %{}
    assert %{"invalid" => _} = json_response(conn, 422)["error"]
  end

  test "updates medication dispense when data is valid", %{conn: conn} do
    %MedicationDispense{id: id} = insert(:medication_dispense)
    conn = put conn, medication_dispense_path(conn, :update, id), medication_dispense: @update_attrs
    resp = json_response(conn, 200)["data"]
    medication_request_id = @update_attrs.medication_request_id
    division_id = @update_attrs.division_id
    legal_entity_id = @update_attrs.legal_entity_id
    status = MedicationDispense.status(:rejected)
    inserted_by = @update_attrs.inserted_by
    updated_by = @update_attrs.updated_by
    dispensed_at = @update_attrs.dispensed_at

    assert %{
      "id" => ^id,
      "medication_request_id" => ^medication_request_id,
      "division_id" => ^division_id,
      "legal_entity_id" => ^legal_entity_id,
      "dispensed_at" => ^dispensed_at,
      "status" => ^status,
      "inserted_by" => ^inserted_by,
      "updated_by" => ^updated_by,
    } = resp
  end

  test "get medication dispense by id", %{conn: conn} do
    medication_dispense = insert(:medication_dispense)
    id = medication_dispense.id
    conn = get conn, medication_dispense_path(conn, :show, id)
    resp = json_response(conn, 200)["data"]

    medication_request_id = medication_dispense.medication_request_id
    division_id = medication_dispense.division_id
    legal_entity_id = medication_dispense.legal_entity_id
    inserted_by = medication_dispense.inserted_by
    updated_by = medication_dispense.updated_by
    dispensed_at = to_string(medication_dispense.dispensed_at)

    assert %{
      "id" => ^id,
      "medication_request_id" => ^medication_request_id,
      "division_id" => ^division_id,
      "legal_entity_id" => ^legal_entity_id,
      "dispensed_at" => ^dispensed_at,
      "inserted_by" => ^inserted_by,
      "updated_by" => ^updated_by,
    } = resp
  end
end
