defmodule Core.Application do
  @moduledoc false

  use Application
  import Supervisor.Spec

  alias Core.Redis
  alias Core.TelemetryHandler.BlockRepoHandler
  alias Core.TelemetryHandler.ReadRepoHandler
  alias Core.TelemetryHandler.RepoHandler

  def start(_type, _args) do
    :telemetry.attach("log-handler", [:core, :repo, :query], &RepoHandler.handle_event/4, nil)
    :telemetry.attach("log-read-handler", [:core, :read_repo, :query], &ReadRepoHandler.handle_event/4, nil)
    :telemetry.attach("log-block-handler", [:core, :block_repo, :query], &BlockRepoHandler.handle_event/4, nil)

    # List all child processes to be supervised
    children = [
      {Core.ReadRepo, []},
      {Core.Repo, []},
      {Core.BlockRepo, []}
    ]

    children = children ++ get_redis_children()

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_redis_children do
    redis_config = Redis.config()

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
  end
end
