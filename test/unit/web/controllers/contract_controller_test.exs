defmodule OPS.Web.ContractControllerTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias Ecto.UUID

  describe "contract show" do
    test "successfully shows", %{conn: conn} do
      contractor_owner_id = UUID.generate()
      contract = insert(:contract, contractor_owner_id: contractor_owner_id)
      conn = get(conn, contract_path(conn, :show, contract.id))

      assert %{"contractor_owner_id" => ^contractor_owner_id} = json_response(conn, 200)["data"]
    end

    test "founds nothing", %{conn: conn} do
      response =
        conn
        |> get(contract_path(conn, :show, UUID.generate()))
        |> json_response(404)

      assert %{"error" => %{"type" => "not_found"}} = response
    end
  end
end
