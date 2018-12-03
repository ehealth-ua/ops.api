defmodule Core.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Core.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Core.DataCase
      import Core.Factory
      import Core.Test.Helpers
      import Mox
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Core.Repo)
    :ok = Sandbox.checkout(Core.BlockRepo)
    :ok = Sandbox.checkout(Core.EventManagerRepo)

    unless tags[:async] do
      Sandbox.mode(Core.Repo, {:shared, self()})
      Sandbox.mode(Core.BlockRepo, {:shared, self()})
      Sandbox.mode(Core.EventManagerRepo, {:shared, self()})
    end

    :ok
  end
end