defmodule OPS.Web.ContractControllerTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias Ecto.UUID
  alias OPS.Contracts.Contract
  alias OPS.Contracts.ContractEmployee
  alias OPS.Contracts.ContractDivision
  alias OPS.Repo

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

    test "search by legal_entity_id", %{conn: conn} do
      nhs_legal_entity_id = UUID.generate()
      contractor_legal_entity_id = UUID.generate()

      insert(:contract)

      insert(
        :contract,
        nhs_legal_entity_id: nhs_legal_entity_id,
        contractor_legal_entity_id: contractor_legal_entity_id,
        status: Contract.status(:terminated)
      )

      %{id: contract_id} =
        insert(
          :contract,
          nhs_legal_entity_id: nhs_legal_entity_id,
          contractor_legal_entity_id: contractor_legal_entity_id
        )

      assert [%{"id" => ^contract_id}] =
               conn
               |> get(contract_path(conn, :index), status: "VERIFIED", legal_entity_id: nhs_legal_entity_id)
               |> json_response(200)
               |> Map.get("data")

      assert [%{"id" => ^contract_id}] =
               conn
               |> get(contract_path(conn, :index), status: "VERIFIED", legal_entity_id: contractor_legal_entity_id)
               |> json_response(200)
               |> Map.get("data")
    end

    test "ignore invalid search params", %{conn: conn} do
      conn = get(conn, contract_path(conn, :index), %{created_by: UUID.generate()})
      assert [] == json_response(conn, 200)["data"]
    end
  end

  describe "suspend contracts" do
    test "success", %{conn: conn} do
      insert(:contract)
      %{id: id1} = insert(:contract)
      %{id: id2} = insert(:contract)
      %{id: id3} = insert(:contract, is_suspended: true)
      params = [ids: Enum.join([id1, id2, id3, UUID.generate()], ",")]

      assert %{"suspended" => 3} ==
               conn
               |> patch(contract_path(conn, :suspend), params)
               |> json_response(200)
               |> Map.get("data")

      Enum.each([id1, id2, id3], fn id ->
        data =
          conn
          |> get(contract_path(conn, :show, id))
          |> json_response(200)
          |> Map.get("data")

        assert Map.has_key?(data, "is_suspended")
        assert data["is_suspended"]
      end)
    end

    test "invalid ids", %{conn: conn} do
      conn
      |> patch(contract_path(conn, :suspend), ids: "invalid,uuid")
      |> json_response(422)
    end
  end

  describe "renew contracts" do
    test "success", %{conn: conn} do
      insert(:contract)
      %{id: id1} = insert(:contract)
      %{id: id2} = insert(:contract, is_suspended: true)
      %{id: id3} = insert(:contract, is_suspended: true)

      params = [ids: Enum.join([id1, id2, id3, UUID.generate()], ",")]

      assert %{"renewed" => 3} ==
               conn
               |> patch(contract_path(conn, :renew), params)
               |> json_response(200)
               |> Map.get("data")

      Enum.each([id1, id2, id3], fn id ->
        data =
          conn
          |> get(contract_path(conn, :show, id))
          |> json_response(200)
          |> Map.get("data")

        assert Map.has_key?(data, "is_suspended")
        refute data["is_suspended"]
      end)
    end

    test "invalid ids", %{conn: conn} do
      conn
      |> patch(contract_path(conn, :suspend), ids: "invalid,uuid")
      |> json_response(422)
    end
  end

  describe "create contract" do
    test "success create contract with contract_employees and contract_divisions", %{conn: conn} do
      contract_employee =
        :contract_employee
        |> build()
        |> Poison.encode!()
        |> Poison.decode!()

      params =
        :contract
        |> build()
        |> Poison.encode!()
        |> Poison.decode!()
        |> Map.put("contractor_employee_divisions", [contract_employee])
        |> Map.put("contractor_divisions", [UUID.generate()])

      conn = post(conn, contract_path(conn, :create), params)

      assert resp = json_response(conn, 200)
      assert params["contract_number"] == resp["data"]["contract_number"]
    end

    test "success create contract with existing contract_number", %{conn: conn} do
      contract = insert(:contract)

      :contract_employee
      |> insert(contract_id: contract.id)
      |> Poison.encode!()
      |> Poison.decode!()

      :contract_division
      |> insert(contract_id: contract.id)
      |> Poison.encode!()
      |> Poison.decode!()

      params =
        contract
        |> Poison.encode!()
        |> Poison.decode!()
        |> Map.put("id", UUID.generate())
        |> Map.put("contractor_divisions", [UUID.generate()])

      conn = post(conn, contract_path(conn, :create), params)

      assert resp = json_response(conn, 200)

      assert params["contract_number"] == resp["data"]["contract_number"]
      assert 2 = Enum.count(Repo.all(Contract))
      assert 2 = Enum.count(Repo.all(ContractEmployee))
      assert 2 = Enum.count(Repo.all(ContractDivision))
    end

    test "contract by contract_number is not verified", %{conn: conn} do
      contract_employee =
        :contract_employee
        |> build()
        |> Poison.encode!()
        |> Poison.decode!()

      params =
        :contract
        |> insert(status: Contract.status(:terminated))
        |> Poison.encode!()
        |> Poison.decode!()
        |> Map.put("id", UUID.generate())
        |> Map.put("contractor_employee_divisions", [contract_employee])
        |> Map.put("contractor_divisions", [UUID.generate()])

      conn = post(conn, contract_path(conn, :create), params)

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
               ],
               "message" => "There is no active contract with such contract_number"
             } = resp["error"]
    end
  end
end
