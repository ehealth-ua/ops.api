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
        sell_amount: 5,
        discount_amount: 10,
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

  test "search medication dispenses", %{conn: conn} do
    medication_dispense1 =
      :medication_dispense
      |> insert()
      |> Repo.preload(:medication_request)
    insert(:medication_dispense_details, medication_dispense_id: medication_dispense1.id)
    medication_dispense2 =
      :medication_dispense
      |> insert(status: MedicationDispense.status(:processed))
      |> Repo.preload(:medication_request)
    insert(:medication_dispense_details, medication_dispense_id: medication_dispense2.id)
    conn1 = get conn, medication_dispense_path(conn, :index)
    resp = json_response(conn1, 200)["data"]
    assert 2 == length(resp)

    conn2 = get conn, medication_dispense_path(conn, :index, id: medication_dispense1.id)
    resp = json_response(conn2, 200)["data"]
    assert 1 == length(resp)
    assert medication_dispense1.id == hd(resp)["id"]

    conn3 = get conn, medication_dispense_path(conn, :index,
      medication_request_id: medication_dispense1.medication_request_id
    )
    resp = json_response(conn3, 200)["data"]
    assert 1 == length(resp)
    assert medication_dispense1.medication_request.id == hd(resp)["medication_request"]["id"]

    conn4 = get conn, medication_dispense_path(conn, :index,
      legal_entity_id: medication_dispense1.legal_entity_id
    )
    resp = json_response(conn4, 200)["data"]
    assert 1 == length(resp)
    assert medication_dispense1.legal_entity_id == hd(resp)["legal_entity_id"]

    conn5 = get conn, medication_dispense_path(conn, :index,
      division_id: medication_dispense1.division_id
    )
    resp = json_response(conn5, 200)["data"]
    assert 1 == length(resp)
    assert medication_dispense1.division_id == hd(resp)["division_id"]

    conn6 = get conn, medication_dispense_path(conn, :index,
      status: medication_dispense2.status
    )
    resp = json_response(conn6, 200)["data"]
    assert 1 == length(resp)
    assert medication_dispense2.status == hd(resp)["status"]

    conn7 = get conn, medication_dispense_path(conn, :index,
      status: medication_dispense2.status,
      legal_entity_id: medication_dispense2.legal_entity_id,
      division_id: medication_dispense2.division_id,
      medication_request_id: medication_dispense2.medication_request_id,
    )
    resp = json_response(conn7, 200)["data"]
    assert 1 == length(resp)
    assert medication_dispense2.status == hd(resp)["status"]
    assert medication_dispense2.legal_entity_id == hd(resp)["legal_entity_id"]
    assert medication_dispense2.division_id == hd(resp)["division_id"]
    assert medication_dispense2.medication_request.id == hd(resp)["medication_request"]["id"]
  end

  test "search dispenses with pagination", %{conn: conn} do
    Enum.each(1..2, fn _ ->
      :medication_dispense
      |> insert()
      |> Repo.preload(:medication_request)
    end)
    conn = get conn, medication_dispense_path(conn, :index, %{"page_size" => 1})
    resp = json_response(conn, 200)
    assert %{"page_number" => 1,
             "page_size" => 1,
             "total_entries" => 2,
             "total_pages" => 2} == resp["paging"]
  end

  test "creates medication dispense when data is valid", %{conn: conn} do
    insert(:medication_request, id: @create_attrs.medication_request_id)
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
      "medication_request" => %{"id" => ^medication_request_id},
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
    medication_request_id = @update_attrs.medication_request_id
    insert(:medication_request, id: medication_request_id)
    conn = put conn, medication_dispense_path(conn, :update, id), medication_dispense: @update_attrs
    resp = json_response(conn, 200)["data"]
    division_id = @update_attrs.division_id
    legal_entity_id = @update_attrs.legal_entity_id
    status = MedicationDispense.status(:rejected)
    inserted_by = @update_attrs.inserted_by
    updated_by = @update_attrs.updated_by
    dispensed_at = @update_attrs.dispensed_at

    assert %{
      "id" => ^id,
      "medication_request" => %{"id" => ^medication_request_id},
      "division_id" => ^division_id,
      "legal_entity_id" => ^legal_entity_id,
      "dispensed_at" => ^dispensed_at,
      "status" => ^status,
      "inserted_by" => ^inserted_by,
      "updated_by" => ^updated_by,
    } = resp
  end
end
