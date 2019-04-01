defmodule OPS.Application do
  @moduledoc false

  use Application
  alias OPS.Web.Endpoint
  import Supervisor.Spec

  def start(_type, _args) do
    redis_config = OPS.Redis.config()

    children =
      Enum.map(0..(redis_config[:pool_size] - 1), fn connection_index ->
        worker(
          Redix,
          [
            [
              host: redis_config[:host],
              port: redis_config[:port],
              password: redis_config[:password],
              database: redis_config[:database],
              name: :"redis_#{connection_index}"
            ]
          ],
          id: {Redix, connection_index}
        )
      end)

    children = children ++ [Endpoint]

    opts = [strategy: :one_for_one, name: OPS.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end
end
