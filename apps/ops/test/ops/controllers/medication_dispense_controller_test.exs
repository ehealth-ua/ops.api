defmodule OPS.Web.MedicationDispenseControllerTest do
  use OPS.Web.ConnCase

  alias Core.MedicationDispenses.MedicationDispense
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.UUID

  @create_attrs %{
    id: UUID.generate(),
    medication_request_id: UUID.generate(),
    dispensed_by: "John Doe",
    dispensed_at: "2017-08-17",
    party_id: UUID.generate(),
    legal_entity_id: UUID.generate(),
    payment_id: UUID.generate(),
    payment_amount: 12.5,
    employee_id: UUID.generate(),
    division_id: UUID.generate(),
    medical_program_id: UUID.generate(),
    status: MedicationDispense.status(:new),
    is_active: true,
    inserted_by: UUID.generate(),
    updated_by: UUID.generate(),
    dispense_details: [
      %{
        medication_id: UUID.generate(),
        medication_qty: 10,
        sell_price: 18.65,
        reimbursement_amount: 0,
        sell_amount: 5,
        discount_amount: 10
      }
    ]
  }

  @update_attrs %{
    medication_request_id: UUID.generate(),
    party_id: UUID.generate(),
    dispensed_at: "2017-08-01",
    dispensed_by: "Judy Doe",
    status: MedicationDispense.status(:rejected),
    inserted_by: UUID.generate(),
    updated_by: UUID.generate(),
    is_active: false,
    legal_entity_id: UUID.generate(),
    division_id: UUID.generate()
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "search medication dispenses", %{conn: conn} do
    medication_dispense1 =
      :medication_dispense
      |> insert(dispensed_at: Date.add(Date.utc_today(), -2))
      |> Repo.preload(:medication_request)

    insert(:medication_dispense_details, medication_dispense_id: medication_dispense1.id)

    medication_dispense2 =
      :medication_dispense
      |> insert(status: MedicationDispense.status(:processed))
      |> Repo.preload(:medication_request)

    insert(:medication_dispense_details, medication_dispense_id: medication_dispense2.id)
    conn1 = get(conn, medication_dispense_path(conn, :index))
    response_data = json_response(conn1, 200)["data"]
    assert 2 == length(response_data)

    conn2 = get(conn, medication_dispense_path(conn, :index, id: medication_dispense1.id))
    response_data = json_response(conn2, 200)["data"]
    assert 1 == length(response_data)
    assert medication_dispense1.id == hd(response_data)["id"]

    conn3 =
      get(
        conn,
        medication_dispense_path(conn, :index, medication_request_id: medication_dispense1.medication_request_id)
      )

    response_data = json_response(conn3, 200)["data"]
    assert 1 == length(response_data)
    assert medication_dispense1.medication_request.id == hd(response_data)["medication_request"]["id"]

    conn4 = get(conn, medication_dispense_path(conn, :index, legal_entity_id: medication_dispense1.legal_entity_id))
    response_data = json_response(conn4, 200)["data"]
    assert 1 == length(response_data)
    assert medication_dispense1.legal_entity_id == hd(response_data)["legal_entity_id"]

    conn5 = get(conn, medication_dispense_path(conn, :index, division_id: medication_dispense1.division_id))
    response_data = json_response(conn5, 200)["data"]
    assert 1 == length(response_data)
    assert medication_dispense1.division_id == hd(response_data)["division_id"]

    conn6 = get(conn, medication_dispense_path(conn, :index, status: medication_dispense2.status))
    response_data = json_response(conn6, 200)["data"]
    assert 1 == length(response_data)
    assert medication_dispense2.status == hd(response_data)["status"]

    conn7 =
      get(
        conn,
        medication_dispense_path(
          conn,
          :index,
          dispensed_from: to_string(medication_dispense1.dispensed_at),
          dispensed_to: to_string(medication_dispense1.dispensed_at)
        )
      )

    response_data = json_response(conn7, 200)["data"]
    assert 1 == length(response_data)
    assert to_string(medication_dispense1.dispensed_at) == hd(response_data)["dispensed_at"]

    conn8 =
      get(
        conn,
        medication_dispense_path(
          conn,
          :index,
          status: medication_dispense2.status,
          legal_entity_id: medication_dispense2.legal_entity_id,
          division_id: medication_dispense2.division_id,
          medication_request_id: medication_dispense2.medication_request_id,
          dispensed_at: to_string(medication_dispense2.dispensed_at)
        )
      )

    response_data = json_response(conn8, 200)["data"]
    assert 1 == length(response_data)
    assert medication_dispense2.status == hd(response_data)["status"]
    assert medication_dispense2.legal_entity_id == hd(response_data)["legal_entity_id"]
    assert medication_dispense2.division_id == hd(response_data)["division_id"]
    assert medication_dispense2.medication_request.id == hd(response_data)["medication_request"]["id"]
  end

  test "search dispenses with pagination", %{conn: conn} do
    Enum.each(1..2, fn _ ->
      :medication_dispense
      |> insert()
      |> Repo.preload(:medication_request)
    end)

    conn = get(conn, medication_dispense_path(conn, :index, %{"page_size" => 1}))
    response = json_response(conn, 200)
    assert %{"page_number" => 1, "page_size" => 1, "total_entries" => 2, "total_pages" => 2} == response["paging"]
  end

  test "creates medication dispense when data is valid", %{conn: conn} do
    insert(:medication_request, id: @create_attrs.medication_request_id)
    conn = post(conn, medication_dispense_path(conn, :create), medication_dispense: @create_attrs)
    response_data = json_response(conn, 201)["data"]

    medication_request_id = @create_attrs.medication_request_id
    division_id = @create_attrs.division_id
    legal_entity_id = @create_attrs.legal_entity_id
    medical_program_id = @create_attrs.medical_program_id
    status = MedicationDispense.status(:new)
    dispensed_by = @create_attrs.dispensed_by
    inserted_by = @create_attrs.inserted_by
    updated_by = @create_attrs.updated_by
    payment_id = @create_attrs.payment_id
    payment_amount = @create_attrs.payment_amount

    assert %{
             "id" => _id,
             "medication_request" => %{"id" => ^medication_request_id},
             "medical_program_id" => ^medical_program_id,
             "division_id" => ^division_id,
             "legal_entity_id" => ^legal_entity_id,
             "payment_id" => ^payment_id,
             "payment_amount" => ^payment_amount,
             "dispensed_by" => ^dispensed_by,
             "dispensed_at" => "2017-08-17",
             "status" => ^status,
             "inserted_by" => ^inserted_by,
             "updated_by" => ^updated_by
           } = response_data
  end

  test "creates medication dispense when data is valid and does not contain medical_program_id", %{conn: conn} do
    insert(:medication_request, id: @create_attrs.medication_request_id)

    conn =
      post(conn, medication_dispense_path(conn, :create),
        medication_dispense: Map.delete(@create_attrs, :medical_program_id)
      )

    response_data = json_response(conn, 201)["data"]

    medication_request_id = @create_attrs.medication_request_id
    division_id = @create_attrs.division_id
    legal_entity_id = @create_attrs.legal_entity_id
    status = MedicationDispense.status(:new)
    dispensed_by = @create_attrs.dispensed_by
    inserted_by = @create_attrs.inserted_by
    updated_by = @create_attrs.updated_by
    payment_id = @create_attrs.payment_id
    payment_amount = @create_attrs.payment_amount

    assert %{
             "id" => _id,
             "medication_request" => %{"id" => ^medication_request_id},
             "medical_program_id" => nil,
             "division_id" => ^division_id,
             "legal_entity_id" => ^legal_entity_id,
             "payment_id" => ^payment_id,
             "payment_amount" => ^payment_amount,
             "dispensed_by" => ^dispensed_by,
             "dispensed_at" => "2017-08-17",
             "status" => ^status,
             "inserted_by" => ^inserted_by,
             "updated_by" => ^updated_by
           } = response_data
  end

  test "creates medication dispense without optional params", %{conn: conn} do
    insert(:medication_request, id: @create_attrs.medication_request_id)
    params = Map.drop(@create_attrs, ~w(payment_id payment_amount dispensed_by)a)
    conn = post(conn, medication_dispense_path(conn, :create), medication_dispense: params)
    response_data = json_response(conn, 201)["data"]

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
             "payment_id" => nil,
             "payment_amount" => nil,
             "dispensed_by" => nil,
             "dispensed_at" => "2017-08-17",
             "status" => ^status,
             "inserted_by" => ^inserted_by,
             "updated_by" => ^updated_by
           } = response_data
  end

  test "create medication dispense with invalid params", %{conn: conn} do
    conn = post(conn, medication_dispense_path(conn, :create), medication_dispense: %{})
    assert %{"invalid" => _} = json_response(conn, 422)["error"]
  end

  test "updates medication dispense when data is valid", %{conn: conn} do
    %MedicationDispense{id: id} = insert(:medication_dispense)
    medication_request_id = @update_attrs.medication_request_id
    insert(:medication_request, id: medication_request_id)
    conn = put(conn, medication_dispense_path(conn, :update, id), medication_dispense: @update_attrs)
    response_data = json_response(conn, 200)["data"]

    division_id = @update_attrs.division_id
    legal_entity_id = @update_attrs.legal_entity_id
    status = MedicationDispense.status(:rejected)
    inserted_by = @update_attrs.inserted_by
    updated_by = @update_attrs.updated_by
    dispensed_by = @update_attrs.dispensed_by
    dispensed_at = @update_attrs.dispensed_at

    assert %{
             "id" => ^id,
             "medication_request" => %{"id" => ^medication_request_id},
             "division_id" => ^division_id,
             "legal_entity_id" => ^legal_entity_id,
             "dispensed_by" => ^dispensed_by,
             "dispensed_at" => ^dispensed_at,
             "status" => ^status,
             "inserted_by" => ^inserted_by,
             "updated_by" => ^updated_by
           } = response_data
  end

  test "process medication dispense", %{conn: conn} do
    %MedicationDispense{id: id, medication_request: medication_request} = insert(:medication_dispense)
    medication_request_id = medication_request.id

    user_id = UUID.generate()
    status = MedicationDispense.status(:processed)

    dispense_params = %{
      "payment_id" => UUID.generate(),
      "payment_amount" => 100,
      "status" => status,
      "updated_by" => user_id
    }

    request_status = MedicationRequest.status(:completed)
    request_params = %{"status" => request_status, "updated_by" => user_id}

    resp =
      conn
      |> patch(medication_dispense_path(conn, :process, id),
        medication_dispense: dispense_params,
        medication_request: request_params
      )
      |> json_response(200)

    assert %{
             "id" => ^id,
             "medication_request" => %{"id" => ^medication_request_id, "status" => ^request_status},
             "payment_amount" => 100.0,
             "status" => ^status,
             "updated_by" => ^user_id
           } = resp["data"]
  end
end
