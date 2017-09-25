defmodule OPS.Integration.DeclarationAutoApproveTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias OPS.Declarations
  alias OPS.Declarations.Declaration
  alias OPS.Repo

  test "approve_declarations/0" do
    declaration = insert(:declaration, status: Declaration.status(:pending))
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

    declaration
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> Repo.update()

    Declarations.approve_declarations()

    active_status = Declaration.status(:active)
    assert %{status: ^active_status} = Repo.get(Declaration, declaration.id)
  end
end
