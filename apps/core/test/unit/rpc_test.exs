defmodule Core.RpcTest do
  @moduledoc false

  use Core.DataCase
  alias Core.MedicationRequests.MedicationRequest
  alias Core.Rpc
  alias Ecto.UUID

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
      medication_id = UUID.generate()
      medical_program_id = UUID.generate()

      search_params = %{
        "person_id" => person_id,
        "medication_id" => medication_id,
        "medical_program_id" => medical_program_id,
        "status" => Enum.join([MedicationRequest.status(:active), MedicationRequest.status(:completed)], ",")
      }

      max_ended_at = Date.add(Date.utc_today(), 3)

      # valid medication requests

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 1),
        person_id: person_id,
        medication_id: medication_id,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:completed)
      )

      insert(:medication_request,
        ended_at: max_ended_at,
        person_id: person_id,
        medication_id: medication_id,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:active)
      )

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 2),
        person_id: person_id,
        medication_id: medication_id,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:completed)
      )

      # invalid medication requests

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 4),
        person_id: person_id,
        medication_id: medication_id,
        medical_program_id: medical_program_id,
        status: MedicationRequest.status(:rejected)
      )

      insert(:medication_request,
        ended_at: Date.add(Date.utc_today(), 5),
        person_id: UUID.generate(),
        medication_id: medication_id,
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
      assert {:ok, []} = Rpc.declarations_by_employees([], [:id])
    end

    test "success get declarations" do
      declaration1 = insert(:declaration)
      declaration2 = insert(:declaration)
      legal_entity_id1 = declaration1.legal_entity_id
      legal_entity_id2 = declaration2.legal_entity_id

      assert {:ok, [%{legal_entity_id: ^legal_entity_id1}, %{legal_entity_id: ^legal_entity_id2}]} =
               Rpc.declarations_by_employees([declaration1.employee_id, declaration2.employee_id], [:legal_entity_id])
    end
  end

  describe "get_declaration/1" do
    test "success" do
      declaration1 = %{id: declaration_id} = insert(:declaration)
      declaration2 = %{declaration_number: declaration_number} = insert(:declaration)

      assert declaration1 == Rpc.get_declaration(id: declaration_id)
      assert declaration2 == Rpc.get_declaration(declaration_number: declaration_number)
    end

    test "not found" do
      assert nil == Rpc.get_declaration(id: UUID.generate())
    end
  end

  describe "search_declarations/3" do
    test "success with limit, offset" do
      insert(:declaration)
      declaration1 = insert(:declaration)
      declaration2 = insert(:declaration)
      insert(:declaration)

      assert {:ok, [declaration1, declaration2]} == Rpc.search_declarations([], [], {1, 2})
    end

    test "success with order by" do
      declaration1 = insert(:declaration)
      insert_list(3, :declaration, is_active: false)
      declaration2 = insert(:declaration)

      assert {:ok, [declaration1, declaration2]} == Rpc.search_declarations([], [desc: :is_active], {0, 2})
    end
  end
end
