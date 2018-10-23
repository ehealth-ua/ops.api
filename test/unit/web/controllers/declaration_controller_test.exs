defmodule OPS.Web.DeclarationControllerTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias OPS.Declarations
  alias OPS.Declarations.Declaration
  alias OPS.Declarations.DeclarationStatusHistory
  alias OPS.EventManagerRepo
  alias OPS.EventManager.Event
  alias Ecto.UUID

  @create_attrs %{
    id: UUID.generate(),
    employee_id: UUID.generate(),
    start_date: "2016-10-10",
    end_date: "2016-12-07",
    status: "active",
    signed_at: "2016-10-09T23:50:07.000000Z",
    created_by: UUID.generate(),
    updated_by: UUID.generate(),
    is_active: true,
    scope: "family_doctor",
    division_id: UUID.generate(),
    legal_entity_id: UUID.generate()
  }

  @update_attrs %{
    employee_id: UUID.generate(),
    person_id: UUID.generate(),
    start_date: "2016-10-11",
    end_date: "2016-12-08",
    status: "closed",
    signed_at: "2016-10-10T23:50:07.000000Z",
    created_by: UUID.generate(),
    updated_by: UUID.generate(),
    is_active: false,
    scope: "family_doctor",
    division_id: UUID.generate(),
    legal_entity_id: UUID.generate()
  }

  @invalid_attrs %{
    division_id: "invalid"
  }

  setup %{conn: conn} do
    insert_initial_block()

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get(conn, declaration_path(conn, :index))
    assert json_response(conn, 200)["data"] == []
  end

  test "max page size", %{conn: conn} do
    for _i <- 1..110 do
      insert(:declaration)
    end

    conn = get(conn, declaration_path(conn, :index), page_size: 1000)
    assert 100 == length(json_response(conn, 200)["data"])
  end

  test "searches entries", %{conn: conn} do
    %{employee_id: doctor_id_1} = fixture(:declaration)
    %{employee_id: doctor_id_2} = fixture(:declaration)

    conn = get(conn, declaration_path(conn, :index) <> "?employee_id=#{doctor_id_1}")

    assert [resp_declaration] = json_response(conn, 200)["data"]
    assert doctor_id_1 == resp_declaration["employee_id"]
    refute doctor_id_2 == resp_declaration["employee_id"]
  end

  test "search declarations by legal_entity_id and", %{conn: conn} do
    %{employee_id: employee_id, legal_entity_id: legal_entity_id, id: id} = fixture(:declaration)
    fixture(:declaration)

    conn = get(conn, declaration_path(conn, :index), legal_entity_id: legal_entity_id, employee_id: employee_id)

    assert [resp_declaration] = json_response(conn, 200)["data"]
    assert id == resp_declaration["id"]
    assert employee_id == resp_declaration["employee_id"]
    assert legal_entity_id == resp_declaration["legal_entity_id"]
    assert Map.has_key?(resp_declaration, "reason")
    assert Map.has_key?(resp_declaration, "reason_description")
  end

  test "search declarations from cabinet", %{conn: conn} do
    person_id = UUID.generate()
    start_year = "2018"
    start_date_expected = "2018-01-01"

    insert(:declaration, person_id: person_id, status: Declaration.status(:active), start_date: start_date_expected)
    insert(:declaration, person_id: person_id, status: Declaration.status(:pending), start_date: "2017-01-01")
    insert(:declaration, person_id: person_id, status: Declaration.status(:rejected), start_date: start_date_expected)
    insert(:declaration, start_date: "2017-01-01")

    # search active
    response = perform_declaration_request(conn, %{person_id: person_id, status: Declaration.status(:active)})
    assert 1 === Enum.count(response)
    assert [person_id] === get_declarations_property(response, "person_id")
    assert [Declaration.status(:active)] === get_declarations_property(response, "status")

    # search with all with particual year
    response = perform_declaration_request(conn, %{person_id: person_id, start_year: start_year})
    assert [start_date_expected, start_date_expected] === get_declarations_property(response, "start_date")
  end

  test "ignore invalid search params", %{conn: conn} do
    conn = get(conn, declaration_path(conn, :index) <> "?created_by=nil")
    assert [] == json_response(conn, 200)["data"]
  end

  test "search declarations by status", %{conn: conn} do
    %{id: id} = fixture(:declaration, Map.put(@create_attrs, :status, "terminated"))

    conn = get(conn, declaration_path(conn, :index), id: id, status: "active")

    assert length(json_response(conn, 200)["data"]) == 0
  end

  test "search declarations by statuses active and pending_verification", %{conn: conn} do
    fixture(:declaration)
    fixture(:declaration, Map.put(@create_attrs, :status, "pending_verification"))

    conn = get(conn, declaration_path(conn, :index), status: "active,pending_verification")

    assert length(json_response(conn, 200)["data"]) == 2
  end

  test "creates declaration and renders declaration when data is valid", %{conn: conn} do
    declaration_number = UUID.generate()

    params =
      @create_attrs
      |> Map.put("declaration_request_id", UUID.generate())
      |> Map.put("person_id", UUID.generate())
      |> Map.put("declaration_number", declaration_number)

    conn = post(conn, declaration_path(conn, :create), declaration: params)
    assert %{"id" => id, "inserted_at" => inserted_at, "updated_at" => updated_at} = json_response(conn, 201)["data"]

    assert id == @create_attrs.id
    conn = get(conn, declaration_path(conn, :show, id))

    assert json_response(conn, 200)["data"] == %{
             "id" => id,
             "person_id" => params["person_id"],
             "employee_id" => @create_attrs.employee_id,
             "division_id" => @create_attrs.division_id,
             "legal_entity_id" => @create_attrs.legal_entity_id,
             "scope" => "family_doctor",
             "start_date" => "2016-10-10",
             "end_date" => "2016-12-07",
             "signed_at" => "2016-10-09T23:50:07.000000Z",
             "status" => "active",
             "reason" => nil,
             "reason_description" => nil,
             "declaration_request_id" => params["declaration_request_id"],
             "inserted_at" => inserted_at,
             "created_by" => @create_attrs.created_by,
             "updated_at" => updated_at,
             "updated_by" => @create_attrs.updated_by,
             "is_active" => true,
             "declaration_number" => declaration_number
           }

    declaration_status_hstr = Repo.one!(DeclarationStatusHistory)
    assert declaration_status_hstr.declaration_id == id
  end

  test "does not create declaration and renders errors when data is invalid", %{conn: conn} do
    conn = post(conn, declaration_path(conn, :create), declaration: @invalid_attrs)
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "creates declaration and terminates other person declarations when data is valid", %{conn: conn} do
    %{id: id1, person_id: person_id} = fixture(:declaration)

    params =
      @create_attrs
      |> Map.put(:person_id, person_id)
      |> Map.put(:declaration_request_id, UUID.generate())
      |> Map.put(:overlimit, true)
      |> Map.put(:declaration_number, to_string(Enum.random(1..1000)))

    %{id: id2} = fixture(:declaration, params)
    conn = post(conn, declaration_path(conn, :create_with_termination_logic), params)
    resp = json_response(conn, 200)
    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp["data"], "id")
    assert id = resp["data"]["id"]
    assert %{overlimit: true} = Repo.get(Declaration, id)

    %{id: ^id} = Declarations.get_declaration!(id)

    %{status: status} = Declarations.get_declaration!(id1)
    assert "terminated" == status

    %{status: status} = Declarations.get_declaration!(id2)
    assert "active" == status

    assert [event1] = EventManagerRepo.all(Event)

    assert %Event{
             entity_type: "Declaration",
             entity_id: ^id1,
             event_type: "StatusChangeEvent",
             properties: %{"status" => %{"new_value" => "terminated"}}
           } = event1
  end

  test "doesn't terminate other declarations and renders errors when data is invalid", %{conn: conn} do
    %{id: id} = fixture(:declaration)
    invalid_attrs = Map.put(@invalid_attrs, :person_id, "person_id")
    conn = post(conn, declaration_path(conn, :create_with_termination_logic), invalid_attrs)
    resp = json_response(conn, 422)
    assert Map.has_key?(resp, "error")

    %{status: status} = Declarations.get_declaration!(id)
    assert "active" == status
  end

  test "updates chosen declaration and renders declaration when data is valid", %{conn: conn} do
    declaration_number = UUID.generate()
    declaration = insert(:declaration, declaration_number: declaration_number)
    %Declaration{id: id, declaration_request_id: declaration_request_id} = declaration
    conn = put(conn, declaration_path(conn, :update, declaration), declaration: @update_attrs)
    assert %{"id" => ^id, "inserted_at" => inserted_at, "updated_at" => updated_at} = json_response(conn, 200)["data"]

    conn = get(conn, declaration_path(conn, :show, id))

    assert json_response(conn, 200)["data"] == %{
             "id" => id,
             "person_id" => @update_attrs.person_id,
             "employee_id" => @update_attrs.employee_id,
             "division_id" => @update_attrs.division_id,
             "legal_entity_id" => @update_attrs.legal_entity_id,
             "scope" => "family_doctor",
             "start_date" => "2016-10-11",
             "end_date" => "2016-12-08",
             "signed_at" => "2016-10-10T23:50:07.000000Z",
             "status" => "closed",
             "reason" => nil,
             "reason_description" => nil,
             "declaration_request_id" => declaration_request_id,
             "inserted_at" => inserted_at,
             "created_by" => @update_attrs.created_by,
             "updated_at" => updated_at,
             "updated_by" => @update_attrs.updated_by,
             "is_active" => false,
             "declaration_number" => declaration_number
           }

    declaration_status_hstrs = Repo.all(DeclarationStatusHistory)
    assert Enum.all?(declaration_status_hstrs, &(Map.get(&1, :declaration_id) == id))
    assert 2 = Enum.count(declaration_status_hstrs)
    assert ~w(active closed) == Enum.map(declaration_status_hstrs, &Map.get(&1, :status))
    assert [event] = EventManagerRepo.all(Event)

    assert %Event{
             entity_type: "Declaration",
             entity_id: ^id,
             event_type: "StatusChangeEvent",
             properties: %{"status" => %{"new_value" => "closed"}}
           } = event
  end

  @tag pending: true
  test "does not update chosen declaration and renders errors when data is invalid", %{conn: conn} do
    declaration = fixture(:declaration)
    conn = put(conn, declaration_path(conn, :update, declaration), declaration: @invalid_attrs)
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen declaration", %{conn: conn} do
    declaration = fixture(:declaration)
    conn = delete(conn, declaration_path(conn, :delete, declaration))
    assert response(conn, 204)

    assert_error_sent(404, fn ->
      get(conn, declaration_path(conn, :show, declaration))
    end)
  end

  test "terminates declarations for given employee_id", %{conn: conn} do
    user_id = "ab4b2245-55c9-46eb-9ac6-c751020a46e3"
    employee_id = "84e30a11-94bd-49fe-8b1f-f5511c5916d6"

    %{id: id} = insert(:declaration, employee_id: employee_id)

    payload = %{employee_id: employee_id, user_id: user_id, reason: "Manual", reason_description: "Employee dies"}

    response_decl =
      conn
      |> patch("/employees/#{employee_id}/declarations/actions/terminate", payload)
      |> json_response(200)
      |> get_in(["data", "terminated_declarations"])
      |> List.first()

    assert id == response_decl["id"]
    assert user_id == response_decl["updated_by"]
    assert "Manual" == response_decl["reason"]
    assert "Employee dies" == response_decl["reason_description"]
  end

  test "no declarations for terminating", %{conn: conn} do
    user_id = "ab4b2245-55c9-46eb-9ac6-c751020a46e3"
    employee_id = "84e30a11-94bd-49fe-8b1f-f5511c5916d6"
    payload = %{employee_id: employee_id, user_id: user_id}

    resp =
      conn
      |> patch("/employees/#{employee_id}/declarations/actions/terminate", payload)
      |> json_response(200)

    assert [] == resp["data"]["terminated_declarations"]
  end

  test "terminates declarations for given person_id", %{conn: conn} do
    user_id = Confex.fetch_env!(:ops, :system_user)
    person_id = "84e30a11-94bd-49fe-8b1f-f5511c5916d6"

    %{id: id} = insert(:declaration, person_id: person_id)
    payload = %{reason: "Manual", reason_description: "Person cheater"}

    response_decl =
      conn
      |> patch("/persons/#{person_id}/declarations/actions/terminate", payload)
      |> json_response(200)
      |> get_in(["data", "terminated_declarations"])
      |> List.first()

    assert id == response_decl["id"]
    assert user_id == Repo.get(Declaration, id).updated_by
    assert user_id == response_decl["updated_by"]
    refute Map.has_key?(response_decl, "is_active")
    assert "Manual" == response_decl["reason"]
    assert "Person cheater" == response_decl["reason_description"]
  end

  test "terminates declarations for given person_id with updated_by param", %{conn: conn} do
    user_id = UUID.generate()
    person_id = "84e30a11-94bd-49fe-8b1f-f5511c5916d6"

    dec = fixture(:declaration)
    Repo.update_all(Declaration, set: [person_id: person_id])
    payload = %{reason: "Person died", user_id: user_id}
    conn = patch(conn, "/persons/#{person_id}/declarations/actions/terminate", payload)

    response = json_response(conn, 200)
    response_decl = List.first(response["data"]["terminated_declarations"])

    assert dec.id == response_decl["id"]
    assert user_id == Repo.get(Declaration, dec.id).updated_by
    assert user_id == response_decl["updated_by"]
    assert "Person died" == response_decl["reason"]
  end

  describe "count declarations" do
    test "success count declarations by employee_ids", %{conn: conn} do
      employee_id1 = UUID.generate()
      employee_id2 = UUID.generate()
      insert(:declaration, employee_id: employee_id1)
      insert(:declaration, employee_id: employee_id2)
      conn = post(conn, declaration_path(conn, :declarations_count, ids: [employee_id1, employee_id2]))

      assert resp = json_response(conn, 200)
      assert %{"count" => 2} == resp["data"]
    end

    test "no ids parameter sent", %{conn: conn} do
      conn = post(conn, declaration_path(conn, :declarations_count))
      assert json_response(conn, 422)
    end

    test "count only active and pending declarations", %{conn: conn} do
      employee_id1 = UUID.generate()
      insert(:declaration, employee_id: employee_id1, status: Declaration.status(:active))
      insert(:declaration, employee_id: employee_id1, status: Declaration.status(:pending))
      insert(:declaration, employee_id: employee_id1, status: Declaration.status(:closed))
      insert(:declaration, employee_id: employee_id1, status: Declaration.status(:terminated))
      conn = post(conn, declaration_path(conn, :declarations_count, ids: [employee_id1]))

      assert resp = json_response(conn, 200)
      assert %{"count" => 2} == resp["data"]
    end
  end

  describe "get person ids" do
    test "success", %{conn: conn} do
      employee_id1 = UUID.generate()
      employee_id2 = UUID.generate()
      %{person_id: person_id1} = insert(:declaration, employee_id: employee_id1)
      %{person_id: person_id2} = insert(:declaration, employee_id: employee_id2)

      resp_data =
        conn
        |> post(declaration_path(conn, :person_ids), employee_ids: [employee_id1, employee_id2])
        |> json_response(200)
        |> Map.get("data")

      assert person_id1 in resp_data["person_ids"]
      assert person_id2 in resp_data["person_ids"]
    end

    test "empty params", %{conn: conn} do
      assert [] =
               conn
               |> post(declaration_path(conn, :person_ids), employee_ids: [])
               |> json_response(200)
               |> get_in(["data", "person_ids"])
    end

    test "error on missed param", %{conn: conn} do
      assert conn
             |> post(declaration_path(conn, :person_ids))
             |> json_response(422)
    end
  end

  describe "terminate declaration" do
    test "invalid declaration id", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        patch(conn, declaration_path(conn, :terminate_declaration, UUID.generate()))
      end
    end

    test "no reason and updated field", %{conn: conn} do
      declaration = insert(:declaration)

      assert_raise(KeyError, fn ->
        patch(conn, declaration_path(conn, :terminate_declaration, declaration.id))
      end)
    end

    test "success terminate declaration", %{conn: conn} do
      declaration = insert(:declaration, status: Declaration.status(:active))
      updated_by = UUID.generate()

      conn =
        patch(conn, declaration_path(conn, :terminate_declaration, declaration.id), %{
          "reason" => "manual_person",
          "updated_by" => updated_by
        })

      declaration_id = declaration.id
      terminated = Declaration.status(:terminated)

      assert %{
               "data" => %{
                 "updated_by" => ^updated_by,
                 "id" => ^declaration_id,
                 "reason" => "manual_person",
                 "status" => ^terminated
               }
             } = json_response(conn, 200)
    end

    test "success terminate pending_verification declaration", %{conn: conn} do
      declaration = insert(:declaration, status: Declaration.status(:pending))
      updated_by = UUID.generate()

      conn =
        patch(conn, declaration_path(conn, :terminate_declaration, declaration.id), %{
          "reason" => "manual_person",
          "updated_by" => updated_by
        })

      declaration_id = declaration.id
      terminated = Declaration.status(:terminated)

      assert %{
               "data" => %{
                 "updated_by" => ^updated_by,
                 "id" => ^declaration_id,
                 "reason" => "manual_person",
                 "status" => ^terminated
               }
             } = json_response(conn, 200)
    end
  end

  defp fixture(:declaration, attrs \\ @create_attrs) do
    create_attrs =
      attrs
      |> Map.put(:id, UUID.generate())
      |> Map.put(:employee_id, UUID.generate())
      |> Map.put(:legal_entity_id, UUID.generate())
      |> Map.put(:person_id, UUID.generate())
      |> Map.put(:declaration_request_id, UUID.generate())
      |> Map.put(:declaration_number, to_string(Enum.random(1..1000)))

    {:ok, declaration} = Declarations.create_declaration(create_attrs)
    declaration
  end

  defp perform_declaration_request(conn, params) do
    conn
    |> get(declaration_path(conn, :index), params)
    |> json_response(200)
    |> Access.get("data")
  end

  defp get_declarations_property(declarations, property),
    do: Enum.map(declarations, fn declaration -> declaration[property] end)
end
