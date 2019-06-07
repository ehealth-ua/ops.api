defmodule OpsScheduler.Jobs.CacheDeclarationsCountJobTest do
  @moduledoc false

  use Core.DataCase

  alias Core.Declarations
  alias Core.Declarations.Declaration
  alias Ecto.UUID
  alias OpsScheduler.Jobs.CacheDeclarationsCountJob
  alias Core.Redis

  @status_active Declaration.status(:active)
  @status_terminated Declaration.status(:terminated)
  @status_pending_verification Declaration.status(:pending)

  setup :verify_on_exit!

  test "run/0" do
    legal_entity_id1 = UUID.generate()
    legal_entity_id2 = UUID.generate()
    legal_entity_id3 = UUID.generate()
    legal_entity_id4 = UUID.generate()

    insert(:declaration, legal_entity_id: legal_entity_id1)
    insert_list(10, :declaration, legal_entity_id: legal_entity_id1, status: @status_terminated)

    insert_list(2, :declaration, legal_entity_id: legal_entity_id2, status: @status_active)
    insert_list(4, :declaration, legal_entity_id: legal_entity_id3, status: @status_terminated)
    insert_list(8, :declaration, legal_entity_id: legal_entity_id4, status: @status_pending_verification)

    Redis.flush()
    CacheDeclarationsCountJob.run()

    get_count = &Redis.get(Declarations.get_cache_key(&1))

    assert {:ok, 11} == get_count.(%{legal_entity_id: legal_entity_id1})
    assert {:ok, 2} == get_count.(%{legal_entity_id: legal_entity_id2, status: @status_active})
    assert {:ok, 4} == get_count.(%{legal_entity_id: legal_entity_id3, status: @status_terminated})
    assert {:ok, 8} == get_count.(%{legal_entity_id: legal_entity_id4, status: @status_pending_verification})
  end
end
