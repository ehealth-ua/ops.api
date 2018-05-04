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

  describe "contract list" do
    setup %{conn: conn} do
      search_params = %{
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        status: "VERIFIED",
        is_suspended: true,
        date_from_start_date: "2018-01-01",
        date_to_start_date: "2019-01-01",
        date_from_end_date: "2018-01-01",
        date_to_end_date: "2019-01-01",
        contract_number: "0000-9EAX-XT7X-3115",
        page: 1,
        page_size: 100
      }

      {:ok, %{conn: conn, search_params: search_params}}
    end

    test "lists all entries on index (empty)", %{conn: conn} do
      conn = get(conn, contract_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end

    test "lists all entries on index (with entries)", %{conn: conn} do
      insert_pair(:contract)
      conn = get(conn, contract_path(conn, :index))

      assert length(json_response(conn, 200)["data"]) == 2
    end

    test "lists with search params", %{conn: conn, search_params: search_params} do
      contract_in =
        insert(:contract, %{
          id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          status: "VERIFIED",
          is_suspended: true,
          start_date: "2018-01-01",
          end_date: "2018-12-31",
          contract_number: "0000-9EAX-XT7X-3115"
        })

      contract_out = insert(:contract, id: UUID.generate())

      conn = get(conn, contract_path(conn, :index), search_params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1

      ids_list = Enum.map(resp, fn contract -> contract["id"] end)
      assert contract_in.id in ids_list
      refute contract_out in ids_list
    end

    test "lists with search params (start_date)", %{conn: conn, search_params: search_params} do
      search_params = Map.delete(search_params, :id)

      contract_in =
        insert(:contract, %{
          contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          status: "VERIFIED",
          is_suspended: true,
          start_date: "2018-01-01",
          end_date: "2018-12-31",
          contract_number: "0000-9EAX-XT7X-3115"
        })

      contract_out =
        insert(:contract, %{
          contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          status: "VERIFIED",
          is_suspended: true,
          start_date: "2017-01-01",
          end_date: "2018-12-31",
          contract_number: "0000-9EAX-XT7X-3115"
        })

      conn = get(conn, contract_path(conn, :index), search_params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1

      ids_list = Enum.map(resp, fn contract -> contract["id"] end)
      assert contract_in.id in ids_list
      refute contract_out in ids_list
    end

    test "lists with search params (end_date)", %{conn: conn, search_params: search_params} do
      search_params = Map.delete(search_params, :id)

      contract_in =
        insert(:contract, %{
          contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          status: "VERIFIED",
          is_suspended: true,
          start_date: "2018-01-01",
          end_date: "2018-12-31",
          contract_number: "0000-9EAX-XT7X-3115"
        })

      contract_out =
        insert(:contract, %{
          contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          status: "VERIFIED",
          is_suspended: true,
          start_date: "2018-01-01",
          end_date: "2019-12-31",
          contract_number: "0000-9EAX-XT7X-3115"
        })

      conn = get(conn, contract_path(conn, :index), search_params)

      assert resp = json_response(conn, 200)["data"]
      assert length(resp) == 1

      ids_list = Enum.map(resp, fn contract -> contract["id"] end)
      assert contract_in.id in ids_list
      refute contract_out in ids_list
    end

    test "list with incorrect page number", %{conn: conn, search_params: search_params} do
      search_params = Map.put(search_params, :page, 2)

      insert(:contract, %{
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        contractor_legal_entity_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        contractor_owner_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        nhs_signer_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        status: "VERIFIED",
        is_suspended: true,
        start_date: "2018-01-01",
        end_date: "2018-12-31",
        contract_number: "0000-9EAX-XT7X-3115"
      })

      insert(:contract, id: UUID.generate())

      conn = get(conn, contract_path(conn, :index), search_params)
      assert json_response(conn, 200)["data"] == []
    end

    test "ignore invalid search params", %{conn: conn} do
      conn = get(conn, contract_path(conn, :index), %{created_by: UUID.generate()})
      assert [] == json_response(conn, 200)["data"]
    end
  end
end
