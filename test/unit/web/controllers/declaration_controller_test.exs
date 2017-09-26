defmodule OPS.Web.DeclarationControllerTest do
  use OPS.Web.ConnCase

  alias OPS.Declarations
  alias OPS.Declarations.Declaration
  alias OPS.Declarations.DeclarationStatusHistory

  @create_attrs %{
    id: Ecto.UUID.generate(),
    employee_id: Ecto.UUID.generate(),
    person_id: Ecto.UUID.generate(),
    start_date: "2016-10-10",
    end_date: "2016-12-07",
    status: "active",
    signed_at: "2016-10-09T23:50:07.000000Z",
    created_by: Ecto.UUID.generate(),
    updated_by: Ecto.UUID.generate(),
    is_active: true,
    scope: "family_doctor",
    division_id: Ecto.UUID.generate(),
    legal_entity_id: Ecto.UUID.generate(),
    declaration_request_id: Ecto.UUID.generate()
  }

  @update_attrs %{
    employee_id: Ecto.UUID.generate(),
    person_id: Ecto.UUID.generate(),
    start_date: "2016-10-11",
    end_date: "2016-12-08",
    status: "closed",
    signed_at: "2016-10-10T23:50:07.000000Z",
    created_by: Ecto.UUID.generate(),
    updated_by: Ecto.UUID.generate(),
    is_active: false,
    scope: "family_doctor",
    division_id: Ecto.UUID.generate(),
    legal_entity_id: Ecto.UUID.generate(),
  }

   @invalid_attrs %{
     division_id: "invalid"
   }

  def fixture(:declaration, attrs \\ @create_attrs) do
    create_attrs =
      attrs
      |> Map.put(:id, Ecto.UUID.generate())
      |> Map.put(:employee_id, Ecto.UUID.generate())
      |> Map.put(:legal_entity_id, Ecto.UUID.generate())

    {:ok, declaration} = Declarations.create_declaration(create_attrs)
    declaration
  end

  setup %{conn: conn} do
    insert_initial_block()

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, declaration_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "searches entries", %{conn: conn} do
    %{employee_id: doctor_id_1} = fixture(:declaration)
    %{employee_id: doctor_id_2} = fixture(:declaration)

    conn = get conn, declaration_path(conn, :index) <> "?employee_id=#{doctor_id_1}"

    assert [resp_declaration] = json_response(conn, 200)["data"]
    assert doctor_id_1 == resp_declaration["employee_id"]
    refute doctor_id_2 == resp_declaration["employee_id"]
  end

  test "search declarations by legal_entity_id and", %{conn: conn} do
    %{employee_id: employee_id, legal_entity_id: legal_entity_id, id: id} = fixture(:declaration)
    fixture(:declaration)

    conn = get conn, declaration_path(conn, :index), [legal_entity_id: legal_entity_id, employee_id: employee_id]

    assert [resp_declaration] = json_response(conn, 200)["data"]
    assert id == resp_declaration["id"]
    assert employee_id == resp_declaration["employee_id"]
    assert legal_entity_id == resp_declaration["legal_entity_id"]
  end

  test "ignore invalid search params", %{conn: conn} do
    conn = get conn, declaration_path(conn, :index) <> "?created_by=nil"
    assert [] == json_response(conn, 200)["data"]
  end

  test "search declarations by status", %{conn: conn} do
    %{id: id} = fixture(:declaration, Map.put(@create_attrs, :status, "terminated"))

    conn = get conn, declaration_path(conn, :index), [id: id, status: "active"]

    assert length(json_response(conn, 200)["data"]) == 0
  end

  test "search declarations by statuses active and pending_verification", %{conn: conn} do
    fixture(:declaration)
    fixture(:declaration, Map.put(@create_attrs, :status, "pending_verification"))

    conn = get conn, declaration_path(conn, :index), [status: "active,pending_verification"]

    assert length(json_response(conn, 200)["data"]) == 2
  end

  test "creates declaration and renders declaration when data is valid", %{conn: conn} do
    conn = post conn, declaration_path(conn, :create), declaration: @create_attrs
    assert %{"id" => id, "inserted_at" => inserted_at, "updated_at" => updated_at} = json_response(conn, 201)["data"]

    assert id == @create_attrs.id
    conn = get conn, declaration_path(conn, :show, id)
    assert json_response(conn, 200)["data"] == %{
      "id" => id,
      "person_id" => @create_attrs.person_id,
      "employee_id" => @create_attrs.employee_id,
      "division_id" => @create_attrs.division_id,
      "legal_entity_id" => @create_attrs.legal_entity_id,
      "scope" => "family_doctor",
      "start_date" => "2016-10-10",
      "end_date" => "2016-12-07",
      "signed_at" => "2016-10-09T23:50:07.000000Z",
      "status" => "active",
      "declaration_request_id" => @create_attrs.declaration_request_id,
      "inserted_at" => inserted_at,
      "created_by" => @create_attrs.created_by,
      "updated_at" => updated_at,
      "updated_by" => @create_attrs.updated_by,
      "is_active" => true
    }
    declaration_status_hstr = Repo.one!(DeclarationStatusHistory)
    assert declaration_status_hstr.declaration_id == id
  end

  test "does not create declaration and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, declaration_path(conn, :create), declaration: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "creates declaration and terminates other person declarations when data is valid", %{conn: conn} do
    %{id: id1} = fixture(:declaration)
    %{id: id2} = fixture(:declaration, Map.put(@create_attrs, :person_id, Ecto.UUID.generate()))
    conn = post conn, declaration_path(conn, :create_with_termination_logic), @create_attrs
    resp = json_response(conn, 200)
    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp["data"], "id")
    id = resp["data"]["id"]
    assert id

    %{id: ^id} = Declarations.get_declaration!(id)

    %{status: status} = Declarations.get_declaration!(id1)
    assert "terminated" == status

    %{status: status} = Declarations.get_declaration!(id2)
    assert "active" == status
  end

  test "doesn't terminate other declarations and renders errors when data is invalid", %{conn: conn} do
    %{id: id} = fixture(:declaration)
    invalid_attrs = Map.put(@invalid_attrs, :person_id, "person_id")
    conn = post conn, declaration_path(conn, :create_with_termination_logic), invalid_attrs
    resp = json_response(conn, 422)
    assert Map.has_key?(resp, "error")

    %{status: status} = Declarations.get_declaration!(id)
    assert "active" == status
  end

  test "updates chosen declaration and renders declaration when data is valid", %{conn: conn} do
    %Declaration{id: id} = declaration = fixture(:declaration)
    conn = put conn, declaration_path(conn, :update, declaration), declaration: @update_attrs
    assert %{"id" => ^id, "inserted_at" => inserted_at, "updated_at" => updated_at} = json_response(conn, 200)["data"]

    conn = get conn, declaration_path(conn, :show, id)
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
      "declaration_request_id" => @create_attrs.declaration_request_id,
      "inserted_at" => inserted_at,
      "created_by" => @update_attrs.created_by,
      "updated_at" => updated_at,
      "updated_by" => @update_attrs.updated_by,
      "is_active" => false
    }
    declaration_status_hstrs = Repo.all(DeclarationStatusHistory)
    assert Enum.all?(declaration_status_hstrs, &(Map.get(&1, :declaration_id) == id))
    assert 2 = Enum.count(declaration_status_hstrs)
    assert ~w(active closed) == Enum.map(declaration_status_hstrs, &(Map.get(&1, :status)))
  end

  @tag pending: true
  test "does not update chosen declaration and renders errors when data is invalid", %{conn: conn} do
    declaration = fixture(:declaration)
    conn = put conn, declaration_path(conn, :update, declaration), declaration: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen declaration", %{conn: conn} do
    declaration = fixture(:declaration)
    conn = delete conn, declaration_path(conn, :delete, declaration)
    assert response(conn, 204)
    assert_error_sent 404, fn ->
      get conn, declaration_path(conn, :show, declaration)
    end
  end

  test "terminates declarations for given employee_id", %{conn: conn} do
    user_id = "ab4b2245-55c9-46eb-9ac6-c751020a46e3"
    employee_id = "84e30a11-94bd-49fe-8b1f-f5511c5916d6"

    dec = fixture(:declaration)
    Repo.update_all(Declaration, set: [employee_id: employee_id])

    payload = %{employee_id: employee_id, user_id: user_id}
    conn = patch conn, "/employees/#{employee_id}/declarations/actions/terminate", payload

    response = json_response(conn, 200)

    assert [dec.id] == response["data"]["terminated_declarations"]
  end

  test "terminates declarations for given person_id", %{conn: conn} do
    user_id = Confex.get_env(:ops, :declaration_terminator_user)
    person_id = "84e30a11-94bd-49fe-8b1f-f5511c5916d6"

    dec = fixture(:declaration)

    Repo.update_all(Declaration, set: [person_id: person_id])

    conn = patch conn, "/persons/#{person_id}/declarations/actions/terminate", ""

    response = json_response(conn, 200)

    assert [dec.id] == response["data"]["terminated_declarations"]

    assert user_id == Repo.get(Declaration, dec.id).updated_by
  end
end
