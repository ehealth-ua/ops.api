{:ok, _} = Plug.Adapters.Cowboy.http OPS.MockServer, [], port: Confex.fetch_env!(:ops, :mock)[:port]
{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(OPS.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(OPS.BlockRepo, :manual)
