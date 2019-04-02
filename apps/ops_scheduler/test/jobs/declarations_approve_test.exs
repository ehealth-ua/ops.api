defmodule OpsScheduler.Jobs.DeclarationsApproveTest do
  @moduledoc false

  use Core.DataCase
  import Mox

  alias Core.Declarations.Declaration
  alias Core.Repo
  alias OpsScheduler.Jobs.DeclarationsApprove

  setup :verify_on_exit!

  test "run/0" do
    expect(KafkaMock, :publish_to_event_manager, 10, fn _ -> :ok end)

    expect(IlMock, :get_global_parameters, fn ->
      {:ok,
       %{
         "data" => %{"verification_request_term_unit" => "DAYS", "verification_request_expiration" => "3"}
       }}
    end)

    declaration_ids =
      Enum.map(1..10, fn _ ->
        inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :second)

        declaration =
          insert(:declaration, status: Declaration.status(:pending), inserted_at: inserted_at, reason: "offline")

        declaration.id
      end)

    DeclarationsApprove.run()

    active_status = Declaration.status(:active)
    Enum.each(declaration_ids, fn id -> assert %{status: ^active_status} = Repo.get(Declaration, id) end)
  end
end
