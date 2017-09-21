defmodule OPS.Web.MedicationRequestControllerTest do
  use OPS.Web.ConnCase

  alias OPS.MedicationRequest.Schema, as: MedicationRequest

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "search medication requests", %{conn: conn} do
    medication_request1 = insert(:medication_request)
    medication_request2 = insert(:medication_request, status: MedicationRequest.status(:completed))
    conn1 = get conn, medication_request_path(conn, :index)
    resp = json_response(conn1, 200)["data"]
    assert 2 == length(resp)

    conn2 = get conn, medication_request_path(conn, :index, id: medication_request1.id)
    resp = json_response(conn2, 200)["data"]
    assert 1 == length(resp)
    assert medication_request1.id == hd(resp)["id"]

    conn3 = get conn, medication_request_path(conn, :index,
      person_id: medication_request1.person_id
    )
    resp = json_response(conn3, 200)["data"]
    assert 1 == length(resp)
    assert medication_request1.person_id == hd(resp)["person_id"]

    conn4 = get conn, medication_request_path(conn, :index,
      employee_id: medication_request1.employee_id
    )
    resp = json_response(conn4, 200)["data"]
    assert 1 == length(resp)
    assert medication_request1.employee_id == hd(resp)["employee_id"]

    conn5 = get conn, medication_request_path(conn, :index,
      status: medication_request2.status
    )
    resp = json_response(conn5, 200)["data"]
    assert 1 == length(resp)
    assert medication_request2.status == hd(resp)["status"]

    conn6 = get conn, medication_request_path(conn, :index,
      status: medication_request2.status,
      person_id: medication_request2.person_id,
      employee_id: medication_request2.employee_id,
    )
    resp = json_response(conn6, 200)["data"]
    assert 1 == length(resp)
    assert medication_request2.status == hd(resp)["status"]
    assert medication_request2.person_id == hd(resp)["person_id"]
    assert medication_request2.employee_id == hd(resp)["employee_id"]
  end
end
