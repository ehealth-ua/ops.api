defmodule OPS.Web.MedicationRequestControllerTest do
  use OPS.Web.ConnCase

  alias OPS.MedicationRequest.Schema, as: MedicationRequest
  alias OPS.MedicationDispense.Schema, as: MedicationDispense

  setup %{conn: conn} do
    medication_request1 = insert(:medication_request)
    medication_request2 = insert(:medication_request, status: MedicationRequest.status(:completed))
    {:ok,
     conn: put_req_header(conn, "accept", "application/json"),
     data: [medication_request1, medication_request2]
    }
  end

  describe "search medication requests" do
    test "success default search", %{conn: conn} do
      conn = get conn, medication_request_path(conn, :index)
      resp = json_response(conn, 200)["data"]
      assert 2 == length(resp)
    end

    test "success search by id", %{conn: conn, data: [medication_request1, _]} do
      conn = get conn, medication_request_path(conn, :index, id: medication_request1.id)
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert medication_request1.id == hd(resp)["id"]
    end

    test "success search by person_id", %{conn: conn, data: [medication_request1, _]} do
      conn = get conn, medication_request_path(conn, :index,
        person_id: medication_request1.person_id
      )
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert medication_request1.person_id == hd(resp)["person_id"]
    end

    test "success search by employee_id", %{conn: conn, data: [medication_request1, _]} do
      conn = get conn, medication_request_path(conn, :index,
        employee_id: medication_request1.employee_id
      )
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert medication_request1.employee_id == hd(resp)["employee_id"]
    end

    test "success search by status", %{conn: conn, data: [_, medication_request2]} do
      conn = get conn, medication_request_path(conn, :index,
        status: medication_request2.status
      )
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert medication_request2.status == hd(resp)["status"]
    end

    test "success search by list of statuses", %{conn: conn} do
      conn = get conn, medication_request_path(conn, :index, status: "ACTIVE,COMPLETED")
      resp = json_response(conn, 200)["data"]
      assert 2 == length(resp)
    end

    test "success search by all possible params", %{conn: conn, data: [_, medication_request2]} do
      conn = get conn, medication_request_path(conn, :index,
        status: medication_request2.status,
        person_id: medication_request2.person_id,
        employee_id: medication_request2.employee_id,
      )
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert medication_request2.status == hd(resp)["status"]
      assert medication_request2.person_id == hd(resp)["person_id"]
      assert medication_request2.employee_id == hd(resp)["employee_id"]
    end
  end

  describe "search medication requests for doctors" do
    test "success search", %{conn: conn, data: [medication_request, _]} do
      insert(:declaration,
        employee_id: medication_request.employee_id,
        person_id: medication_request.person_id
      )
      conn = get conn, medication_request_path(conn, :doctor_list, %{
        "employee_id" => "#{medication_request.employee_id},#{Ecto.UUID.generate()}",
        "person_id" => medication_request.person_id,
        "id" => medication_request.id,
      })
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
    end

    test "empty search", %{conn: conn, data: [medication_request, _]} do
      insert(:declaration,
        employee_id: medication_request.employee_id,
        person_id: medication_request.person_id
      )
      conn = get conn, medication_request_path(conn, :doctor_list, %{"status" => "invalid"})
      resp = json_response(conn, 200)["data"]
      assert 0 == length(resp)
    end
  end

  describe "search medication requests by person_id" do
    test "success search", %{conn: conn, data: [medication_request, _]} do
      %{id: id, person_id: person_id} = medication_request
      insert(:medication_dispense,
        medication_request: medication_request,
        status: MedicationDispense.status(:processed)
      )
      conn = get conn, medication_request_path(conn, :person_list, %{"person_id" => person_id})
      resp = json_response(conn, 200)["data"]
      assert [id] == resp
    end

    test "empty search", %{conn: conn} do
      conn = get conn, medication_request_path(conn, :person_list, %{"person_id" => Ecto.UUID.generate()})
      resp = json_response(conn, 200)["data"]
      assert [] == resp
    end

    test "validation failed", %{conn: conn} do
      conn = get conn, medication_request_path(conn, :person_list)
      assert json_response(conn, 422)
    end
  end

  describe "update medication request" do
    test "success update", %{conn: conn, data: [medication_request, _]} do
      conn = patch conn, medication_request_path(conn, :update, medication_request.id), %{
        "medication_request" => %{
          "status" => MedicationRequest.status(:completed),
          "updated_by" => Ecto.UUID.generate(),
        },
      }
      resp = json_response(conn, 200)
      assert MedicationRequest.status(:completed) == resp["data"]["status"]
    end
  end
end
