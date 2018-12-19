defmodule Core.RpcTest do
  @moduledoc false

  use Core.DataCase
  alias Core.Rpc
  alias Ecto.UUID

  describe "existing_max_medication_request/1" do
    test "returns medication request dates with max ended_at when medication requests are found" do
      max_ended_at = Date.add(Date.utc_today(), 3)
      insert(:medication_request, ended_at: Date.add(Date.utc_today(), 1))
      insert(:medication_request, ended_at: max_ended_at)
      insert(:medication_request, ended_at: Date.add(Date.utc_today(), 2))

      {:ok, %{"ended_at" => ended_at}} = Rpc.last_medication_request_dates(%{})
      assert ended_at == max_ended_at
    end

    test "returns nil when medication requests are NOT found" do
      assert {:ok, nil} == Rpc.last_medication_request_dates(%{})
    end

    test "failed when search params are invalid" do
      search_params = %{
        "person_id" => 12345,
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
end