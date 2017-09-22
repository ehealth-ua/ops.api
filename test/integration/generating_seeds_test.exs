defmodule OPS.DeclarationTerminatorTest do
  @moduledoc false

  use OPS.DataCase

  alias OPS.SeedRepo
  alias OPS.Seed.API, as: SeedAPI
  alias OPS.Seed.Schema, as: Seed

  test "start init genserver" do
    {:ok, %{hash: first_hash}} = SeedAPI.close_day(~D[2014-01-01])

    d1 = insert(:declaration, inserted_at: ~N[2014-01-02 01:00:00])
    d2 = insert(:declaration, inserted_at: ~N[2014-01-02 02:00:00])
    assert first_hash = d1.seed
    assert first_hash = d2.seed

    {:ok, %{hash: second_hash}} = SeedAPI.close_day(~D[2014-01-02])

    d3 = insert(:declaration, inserted_at: ~N[2014-01-03 01:00:00])
    d4 = insert(:declaration, inserted_at: ~N[2014-01-03 02:00:00])
    assert second_hash = d1.seed
    assert second_hash = d2.seed

    {:ok, %{hash: third_hash}} = SeedAPI.close_day(~D[2014-01-03])

    assert second_hash = SeedAPI.verify_day(~D[2014-01-02])
    assert third_hash = SeedAPI.verify_day(~D[2014-01-03])

    # SeedAPI.verify_chain()
  end
end
