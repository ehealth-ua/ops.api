defmodule OPS.DataCase do
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

  using do
    quote do
      alias OPS.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import OPS.DataCase
      import OPS.Factory
      import OPS.Test.Helpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(OPS.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(OPS.BlockRepo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(OPS.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(OPS.BlockRepo, {:shared, self()})
    end

    :ok
  end

  def start_microservices(module) do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_string} = :inet.port(port)
    :erlang.port_close(port)
    ref = make_ref()
    {:ok, _pid} = Plug.Adapters.Cowboy.http module, [], port: port_string, ref: ref
    {:ok, port_string, ref}
  end

  def stop_microservices(ref) do
    Plug.Adapters.Cowboy.shutdown(ref)
  end

  @doc """
  Helper for returning list of errors in a struct when given certain data.
  ## Examples
  Given a User schema that lists `:name` as a required field and validates
  `:password` to be safe, it would return:
      iex> errors_on(%User{}, %{password: "password"})
      [password: "is unsafe", name: "is blank"]
  You could then write your assertion like:
      assert {:password, "is unsafe"} in errors_on(%User{}, %{password: "password"})
  """
  def errors_on(struct, data) do
    data
    |> (&struct.__struct__.changeset(struct, &1)).()
    |> Enum.flat_map(fn {key, errors} -> for msg <- errors, do: {key, msg} end)
  end
end
