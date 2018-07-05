defmodule OPS.DeclarationTerminatorTest do
  @moduledoc false

  use OPS.Web.ConnCase

  alias OPS.Declarations.Declaration
  alias OPS.DeclarationsAutoProcessor
  alias OPS.Repo

  test "terminate_declarations/0" do
    declaration_ids =
      Enum.map(1..10, fn _ ->
        inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

        declaration = insert(:declaration, status: Declaration.status(:pending), inserted_at: inserted_at)
        declaration.id
      end)

    DeclarationsAutoProcessor.terminate_declarations()
    assert_receive :autoterminate

    closed_status = Declaration.status(:closed)
    Enum.each(declaration_ids, fn id -> assert %{status: ^closed_status} = Repo.get(Declaration, id) end)
  end
end
