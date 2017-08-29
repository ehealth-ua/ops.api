defmodule OPS.Integration.DeclarationAutoApproveTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias OPS.DeclarationAutoApprove
  alias OPS.Declarations.Declaration
  alias OPS.Repo

  @tag :pending
  test "start init genserver" do
    declaration = insert(:declaration, status: Declaration.status(:pending))
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

    declaration
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> Repo.update()

    GenServer.cast(DeclarationAutoApprove, {:approve, 1})
    Process.sleep(1000)

    active_status = Declaration.status(:active)
    assert %{status: ^active_status} = Repo.get(Declaration, declaration.id)
  end
end
