defmodule OPS.RpcTest do
  @moduledoc false

  use Core.DataCase
  import Mox

  alias Core.MedicationDispenses.MedicationDispense
  alias Core.MedicationRequests.MedicationRequest
  alias Ecto.UUID
  alias OPS.Rpc
  alias OPS.Web.DeclarationView
  alias OPS.Web.MedicationRequestView
  alias Scrivener.Page

  setup :verify_on_exit!

  describe "last_medication_request_dates/1" do
    test "returns medication request dates with max ended_at when medication requests are found" do
      max_ended_at = Date.add(Date.utc_today(), 3)
      insert(:medication_request, ended_at: Date.add(Date.utc_today(), 1))
      insert(:medication_request, ended_at: max_ended_at)
      insert(:medication_request, ended_at: Date.add(Date.utc_today(), 2))

      {:ok, %{"ended_at" => ended_at}} = Rpc.last_medication_request_dates(%{})
      assert ended_at == max_ended_at
    end

    test "returns medication request dates with max ended_at when medication requests are found (using search params)" do
      person_id = UUID.generate()
      medication_id_1 = UUID.generate()
      medication_id_2 = UUID.generate()
      medication_id = Enum.join([medication_id_1, medication_id_2], ",")
      medical_program_id = UUID.generate()

      max_ended_at = Date.add(Date.utc_today(), 3)
      started_at_to = Date.add(Date.utc_today(), 1)

      search_params = %{
        "person_id" => person_id,
        "medication_id" => medication_id,
        "medical_program_id" => medical_program_id,
        "status" => Enum.join([MedicationRequest.status(:active), MedicationRequest.status(:completed)], ","),
        "started_at_to" => started_at_to
      }

      # valid medication requests

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 1),
        person_id: person_id,
        medication_id: medication_id_1,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:completed)
      )

      insert(:medication_request,
        started_at: started_at_to,
        ended_at: max_ended_at,
        person_id: person_id,
        medication_id: medication_id_2,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:active)
      )

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 2),
        person_id: person_id,
        medication_id: medication_id_1,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:completed)
      )

      # invalid medication requests

      insert(:medication_request,
        started_at: Date.add(started_at_to, 2),
        ended_at: Date.add(max_ended_at, 1),
        person_id: person_id,
        medication_id: medication_id_2,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:active)
      )

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 4),
        person_id: person_id,
        medication_id: medication_id_2,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:rejected)
      )

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 5),
        person_id: UUID.generate(),
        medication_id: UUID.generate(),
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:active)
      )

      {:ok, %{"ended_at" => ended_at}} = Rpc.last_medication_request_dates(search_params)
      assert ended_at == max_ended_at
    end

    test "returns nil when medication requests are NOT found" do
      assert {:ok, nil} == Rpc.last_medication_request_dates(%{})
    end

    test "failed when search params are invalid" do
      search_params = %{
        "person_id" => 12_345,
        "medication_id" => "test",
        "medical_program_id" => "test",
        "status" => 123
      }

      assert {:error,
              %{
                invalid: [
                  %{
                    entry: "medical_program_id",
                    entry_type: "query_parameter",
                    rules: [%{description: "is invalid", params: [Ecto.UUID], rule: :cast}]
                  },
                  %{
                    entry: "person_id",
                    entry_type: "query_parameter",
                    rules: [%{description: "is invalid", params: [Ecto.UUID], rule: :cast}]
                  },
                  %{
                    entry: "status",
                    entry_type: "query_parameter",
                    rules: [%{description: "is invalid", params: [:string], rule: :cast}]
                  }
                ]
              }} = Rpc.last_medication_request_dates(search_params)
    end

    test "ignore not provided search params" do
      medication_request_in = insert(:medication_request, ended_at: Date.utc_today())

      medication_request_out =
        insert(:medication_request, person_id: UUID.generate(), ended_at: Date.add(Date.utc_today(), 1))

      search_params = %{
        "person_id" => medication_request_in.person_id,
        "medication_id" => medication_request_in.medication_id,
        "medical_program_id" => medication_request_in.medical_program_id,
        "status" => medication_request_in.status,
        "division_id" => medication_request_out.division_id,
        "employee_id" => medication_request_out.employee_id
      }

      {:ok, %{"ended_at" => ended_at}} = Rpc.last_medication_request_dates(search_params)
      assert ended_at == Date.utc_today()
    end
  end

  describe "declarations_by_employees/2" do
    test "get declarations by empty list of employees" do
      assert [] = Rpc.declarations_by_employees([], [:id])
    end

    test "success get declarations" do
      declaration1 = insert(:declaration)
      declaration2 = insert(:declaration)
      legal_entity_id1 = declaration1.legal_entity_id
      legal_entity_id2 = declaration2.legal_entity_id

      assert [%{legal_entity_id: ^legal_entity_id1}, %{legal_entity_id: ^legal_entity_id2}] =
               Rpc.declarations_by_employees([declaration1.employee_id, declaration2.employee_id], [:legal_entity_id])
    end
  end

  describe "get_declaration/1" do
    test "success" do
      declaration1 = %{id: declaration_id} = insert(:declaration)
      declaration2 = %{declaration_number: declaration_number} = insert(:declaration)
      {:ok, resp_entity1} = Rpc.get_declaration(id: declaration_id)
      {:ok, resp_entity2} = Rpc.get_declaration(declaration_number: declaration_number)
      assert_declarations_equal([declaration1, declaration2], [resp_entity1, resp_entity2])
    end

    test "not found" do
      refute Rpc.get_declaration(id: UUID.generate())
    end
  end

  describe "search_declarations/3" do
    test "success with limit, offset" do
      insert(:declaration)
      declarations = insert_list(2, :declaration)
      insert(:declaration)
      assert {:ok, resp_entities} = Rpc.search_declarations([{:is_active, :equal, true}], [], {1, 2})
      assert_declarations_equal(declarations, resp_entities)
    end

    test "success only with filter" do
      today = Date.utc_today()
      start_date = ~D[2010-10-10]
      declarations = insert_list(2, :declaration, start_date: start_date)
      insert_list(4, :declaration, start_date: today)
      {:ok, resp_entities} = Rpc.search_declarations([{:start_date, :less_than, today}])
      assert 2 == length(resp_entities)
      assert_declarations_equal(declarations, resp_entities)
    end

    test "success by person_id" do
      person_id = UUID.generate()
      insert_list(3, :declaration)
      declarations = insert_list(2, :declaration, person_id: person_id)
      assert {:ok, resp_entities} = Rpc.search_declarations([{:person_id, :in, [person_id]}], [], {0, 10})
      assert 2 == length(resp_entities)
      assert_declarations_equal(declarations, resp_entities)
    end

    test "success with order by" do
      declaration1 = insert(:declaration)
      insert_list(3, :declaration, is_active: false)
      declaration2 = insert(:declaration)
      declarations = [declaration1, declaration2]
      assert {:ok, resp_entities} = Rpc.search_declarations([{:scope, :equal, ""}], [desc: :is_active], {0, 2})
      assert_declarations_equal(declarations, resp_entities)
    end
  end

  describe "update_declaration/2" do
    test "success" do
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      %{id: declaration_id} = insert(:declaration, is_active: true, status: "active", scope: "family_doctor")
      patch = %{status: "closed", is_active: false, updated_by: UUID.generate()}

      assert {:ok, %{id: ^declaration_id, status: "closed", is_active: false}} =
               Rpc.update_declaration(declaration_id, patch)
    end

    test "invalid status transaction" do
      declaration = insert(:declaration, status: "closed")
      patch = %{status: "closed", updated_by: UUID.generate()}
      assert {:error, %Ecto.Changeset{valid?: false}} = Rpc.update_declaration(declaration.id, patch)
    end

    test "not found" do
      refute Rpc.update_declaration(UUID.generate(), %{})
    end
  end

  describe "terminate_declaration/2" do
    test "success" do
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      %{id: declaration_id} = insert(:declaration, status: "active")
      patch = %{"updated_by" => UUID.generate(), "reason" => "manual_person"}
      assert {:ok, %{id: ^declaration_id, status: "terminated"}} = Rpc.terminate_declaration(declaration_id, patch)
    end

    test "invalid status" do
      %{id: declaration_id} = insert(:declaration, status: "terminated")
      patch = %{"updated_by" => UUID.generate(), "reason" => "manual_person"}
      assert {:error, %Ecto.Changeset{valid?: false}} = Rpc.terminate_declaration(declaration_id, patch)
    end
  end

  describe "medication_request_by_id/1" do
    test "success" do
      medication_request = insert(:medication_request)
      expected_data = MedicationRequestView.render("show.json", %{medication_request: medication_request})
      assert expected_data == Rpc.medication_request_by_id(medication_request.id)
    end

    test "id does not exist" do
      refute Rpc.medication_request_by_id(UUID.generate())
    end
  end

  describe "medication_requests/1" do
    test "success search medication_requests by legal_entity_id" do
      insert(:medication_request)
      %{id: id, legal_entity_id: legal_entity_id} = insert(:medication_request)

      assert %Page{entries: [%{id: ^id, legal_entity_id: ^legal_entity_id}]} =
               Rpc.medication_requests(%{"legal_entity_id" => legal_entity_id})
    end

    test "success search medication_request second page" do
      for _ <- 0..9 do
        insert(:medication_request)
      end

      assert %Page{entries: _, total_pages: 2, total_entries: 10} = Rpc.medication_requests(%{"page_size" => 5})
    end
  end

  describe "doctor_medication_requests/1" do
    test "success search medication_requests by legal_entity_id" do
      insert(:medication_request)
      %{id: id, legal_entity_id: legal_entity_id} = insert(:medication_request)

      assert %Page{entries: [%{id: ^id, legal_entity_id: ^legal_entity_id}]} =
               Rpc.doctor_medication_requests(%{"legal_entity_id" => legal_entity_id})
    end

    test "success search medication_request second page" do
      for _ <- 0..9 do
        insert(:medication_request)
      end

      assert %Page{entries: _, total_pages: 2, total_entries: 10} = Rpc.doctor_medication_requests(%{"page_size" => 5})
    end
  end

  describe "medication_dispenses/1" do
    test "success search medication_dispenses by legal_entity_id" do
      legal_entity_id = UUID.generate()

      %{id: id, medication_request: %{id: medication_request_id}} =
        insert(:medication_dispense, legal_entity_id: legal_entity_id)

      assert %Page{
               entries: [
                 %{id: ^id, legal_entity_id: ^legal_entity_id, medication_request: %{id: ^medication_request_id}}
               ]
             } = Rpc.medication_dispenses(%{"legal_entity_id" => legal_entity_id})
    end

    test "success search medication_dispenses second page" do
      for _ <- 0..9 do
        insert(:medication_dispense)
      end

      assert %Page{entries: _, total_pages: 2, total_entries: 10} = Rpc.medication_dispenses(%{"page_size" => 5})
    end
  end

  describe "qualify_medication_requests/1" do
    test "success qualify medication_request" do
      started_at = Date.utc_today()
      ended_at = Date.add(started_at, 5)
      medication_request = insert(:medication_request, started_at: started_at, ended_at: ended_at)
      medication_id = medication_request.medication_id

      insert(:medication_dispense,
        medication_request: medication_request,
        status: MedicationDispense.status(:processed)
      )

      insert(:medication_request)

      assert {:ok, [^medication_id]} =
               Rpc.qualify_medication_requests(%{
                 "person_id" => medication_request.person_id,
                 "started_at" => medication_request.started_at,
                 "ended_at" => medication_request.ended_at
               })
    end
  end

  describe "prequalify_medication_requests/1" do
    test "success prequalify medication_request" do
      started_at = Date.utc_today()
      ended_at = Date.add(started_at, 5)
      medication_request = insert(:medication_request, started_at: started_at, ended_at: ended_at)
      medication_id = medication_request.medication_id

      insert(:medication_request)

      assert {:ok, [^medication_id]} =
               Rpc.prequalify_medication_requests(%{
                 "person_id" => medication_request.person_id,
                 "started_at" => medication_request.started_at,
                 "ended_at" => medication_request.ended_at
               })
    end
  end

  describe "create_medication_request/1" do
    test "success create medication_request" do
      medication_request_id = UUID.generate()

      assert {:ok, %{id: ^medication_request_id}} =
               Rpc.create_medication_request(%{
                 id: medication_request_id,
                 request_number: "1234",
                 person_id: UUID.generate(),
                 division_id: UUID.generate(),
                 medication_id: UUID.generate(),
                 legal_entity_id: UUID.generate(),
                 medication_qty: 20,
                 medication_request_requests_id: UUID.generate(),
                 employee_id: UUID.generate(),
                 created_at: Date.utc_today(),
                 started_at: Date.utc_today(),
                 ended_at: Date.utc_today(),
                 inserted_by: UUID.generate(),
                 updated_by: UUID.generate()
               })
    end
  end

  describe "update_medication_request/2" do
    test "success update medication_request" do
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      %{id: id} = insert(:medication_request)
      status_completed = MedicationRequest.status(:completed)

      assert {:ok, %{id: ^id, status: ^status_completed}} =
               Rpc.update_medication_request(id, %{
                 status: status_completed,
                 updated_by: UUID.generate()
               })
    end
  end

  describe "create_medication_dispense/1" do
    test "success create medication_dispense" do
      medication_dispense_id = UUID.generate()

      assert {:ok, %{id: ^medication_dispense_id}} =
               Rpc.create_medication_dispense(%{
                 id: medication_dispense_id,
                 legal_entity_id: UUID.generate(),
                 medication_request_id: UUID.generate(),
                 dispensed_at: Date.utc_today(),
                 party_id: UUID.generate(),
                 division_id: UUID.generate(),
                 status: MedicationDispense.status(:new),
                 is_active: true,
                 inserted_by: UUID.generate(),
                 updated_by: UUID.generate()
               })
    end
  end

  describe "update_medication_dispense/2" do
    test "success update medication_dispense" do
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      medication_dispense = insert(:medication_dispense)
      medication_dispense_id = medication_dispense.id
      status_processed = MedicationDispense.status(:processed)

      assert {:ok, %{id: ^medication_dispense_id, status: ^status_processed}} =
               Rpc.update_medication_dispense(medication_dispense_id, %{
                 status: status_processed,
                 updated_by: UUID.generate()
               })
    end
  end

  defp assert_declarations_equal([_ | _] = prepared_declarations, [_ | _] = response_declarations) do
    Enum.each(response_declarations, fn declaration ->
      refute Map.has_key?(declaration, :__struct__)
      refute Map.has_key?(declaration, :__meta__)
    end)

    rendered = DeclarationView.render("index.json", %{declarations: prepared_declarations})
    assert MapSet.new(rendered) == MapSet.new(response_declarations)
  end
end
