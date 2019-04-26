defmodule OPS.Web.MedicationDispenseControllerTest do
  use OPS.Web.ConnCase

  import Mox
  alias Core.MedicationDispenses.MedicationDispense
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.UUID

  setup :verify_on_exit!

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
    resp = conn |> get(medication_dispense_path(conn, :index)) |> json_response(200)
    assert 2 == length(resp["data"])

    resp = conn |> get(medication_dispense_path(conn, :index, id: medication_dispense1.id)) |> json_response(200)
    assert 1 == length(resp["data"])
    assert medication_dispense1.id == hd(resp["data"])["id"]

    resp =
      conn
      |> get(medication_dispense_path(conn, :index, medication_request_id: medication_dispense1.medication_request_id))
      |> json_response(200)

    assert 1 == length(resp["data"])
    assert medication_dispense1.medication_request.id == hd(resp["data"])["medication_request"]["id"]

    resp =
      conn
      |> get(medication_dispense_path(conn, :index, legal_entity_id: medication_dispense1.legal_entity_id))
      |> json_response(200)

    assert 1 == length(resp["data"])
    assert medication_dispense1.legal_entity_id == hd(resp["data"])["legal_entity_id"]

    resp =
      conn
      |> get(medication_dispense_path(conn, :index, division_id: medication_dispense1.division_id))
      |> json_response(200)

    assert 1 == length(resp["data"])
    assert medication_dispense1.division_id == hd(resp["data"])["division_id"]

    resp =
      conn |> get(medication_dispense_path(conn, :index, status: medication_dispense2.status)) |> json_response(200)

    assert 1 == length(resp["data"])
    assert medication_dispense2.status == hd(resp["data"])["status"]

    resp =
      conn
      |> get(
        medication_dispense_path(conn, :index,
          dispensed_from: to_string(medication_dispense1.dispensed_at),
          dispensed_to: to_string(medication_dispense1.dispensed_at)
        )
      )
      |> json_response(200)

    assert 1 == length(resp["data"])
    assert to_string(medication_dispense1.dispensed_at) == hd(resp["data"])["dispensed_at"]

    resp =
      conn
      |> get(
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
      |> json_response(200)

    assert 1 == length(resp["data"])
    assert medication_dispense2.status == hd(resp["data"])["status"]
    assert medication_dispense2.legal_entity_id == hd(resp["data"])["legal_entity_id"]
    assert medication_dispense2.division_id == hd(resp["data"])["division_id"]
    assert medication_dispense2.medication_request.id == hd(resp["data"])["medication_request"]["id"]
  end

  test "search dispenses with pagination", %{conn: conn} do
    Enum.each(1..2, fn _ ->
      :medication_dispense
      |> insert()
      |> Repo.preload(:medication_request)
    end)

    response = conn |> get(medication_dispense_path(conn, :index, %{"page_size" => 1})) |> json_response(200)
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

  test "creates medication dispense when data is valid and does not contain medical_program_id",
       %{conn: conn} do
    insert(:medication_request, id: @create_attrs.medication_request_id)

    resp =
      conn
      |> post(medication_dispense_path(conn, :create),
        medication_dispense: Map.delete(@create_attrs, :medical_program_id)
      )
      |> json_response(201)

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
           } = resp["data"]
  end

  test "creates medication dispense without optional params", %{conn: conn} do
    insert(:medication_request, id: @create_attrs.medication_request_id)
    params = Map.drop(@create_attrs, ~w(payment_id payment_amount dispensed_by)a)
    resp = conn |> post(medication_dispense_path(conn, :create), medication_dispense: params) |> json_response(201)

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
           } = resp["data"]
  end

  test "create medication dispense with invalid params", %{conn: conn} do
    conn = post(conn, medication_dispense_path(conn, :create), medication_dispense: %{})
    assert %{"invalid" => _} = json_response(conn, 422)["error"]
  end

  test "updates medication dispense when data is valid", %{conn: conn} do
    expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
    %MedicationDispense{id: id} = insert(:medication_dispense)
    medication_request_id = @update_attrs.medication_request_id
    insert(:medication_request, id: medication_request_id)

    resp =
      conn |> put(medication_dispense_path(conn, :update, id), medication_dispense: @update_attrs) |> json_response(200)

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
           } = resp["data"]
  end

  test "process medication dispense", %{conn: conn} do
    expect(KafkaMock, :publish_to_event_manager, 2, fn _ -> :ok end)
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

  test "process processed medication dispense", %{conn: conn} do
    status = MedicationDispense.status(:processed)
    %MedicationDispense{id: id} = insert(:medication_dispense, status: status)
    user_id = UUID.generate()

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
      |> json_response(422)

    assert %{
             "invalid" => [
               %{
                 "entry" => "$.status",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "Incorrect status transition.",
                     "params" => [],
                     "rule" => nil
                   }
                 ]
               }
             ]
           } = resp["error"]
  end

  test "process medication dispense with existing processed dispense to the same medication request", %{conn: conn} do
    status = MedicationDispense.status(:processed)
    %MedicationDispense{medication_request: medication_request} = insert(:medication_dispense, status: status)
    %MedicationDispense{id: id} = insert(:medication_dispense, medication_request: medication_request)

    user_id = UUID.generate()

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
      |> json_response(422)

    assert %{
             "invalid" => [
               %{
                 "entry" => "$.medication_request_id",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "has already been taken",
                     "params" => [],
                     "rule" => nil
                   }
                 ]
               }
             ]
           } = resp["error"]
  end
end
