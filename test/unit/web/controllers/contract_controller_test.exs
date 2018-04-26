defmodule OPS.Web.ContractControllerTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias Ecto.UUID

  describe "contract show" do
    test "successfully shows", %{conn: conn} do
      contractor_owner_id = UUID.generate()
      contract = insert(:contract, contractor_owner_id: contractor_owner_id)

      assert %{"data" => response_data} = do_contract_show_request(conn, contract.id)
      assert %{"contractor_owner_id" => ^contractor_owner_id} = response_data
    end

    test "founds nothing", %{conn: conn} do
      assert %{"error" => %{"type" => "not_found"}} = do_contract_show_request(conn, UUID.generate(), 404)
    end
  end

  defp do_contract_show_request(conn, id, status_code \\ 200) do
    conn
    |> get(contract_path(conn, :show, id))
    |> json_response(status_code)
  end
end
