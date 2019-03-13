defmodule Core.Application do
  @moduledoc false

  use Application
  alias Core.TelemetryHandler.BlockRepoHandler
  alias Core.TelemetryHandler.EventManagerRepoHandler
  alias Core.TelemetryHandler.ReadRepoHandler
  alias Core.TelemetryHandler.RepoHandler

  def start(_type, _args) do
    :telemetry.attach("log-handler", [:core, :repo, :query], &RepoHandler.handle_event/4, nil)
    :telemetry.attach("log-read-handler", [:core, :read_repo, :query], &ReadRepoHandler.handle_event/4, nil)
    :telemetry.attach("log-block-handler", [:core, :block_repo, :query], &BlockRepoHandler.handle_event/4, nil)

    :telemetry.attach(
      "log-event-manager-handler",
      [:core, :event_manager_repo, :query],
      &EventManagerRepoHandler.handle_event/4,
      nil
    )

    # List all child processes to be supervised
    children = [
      {Core.ReadRepo, []},
      {Core.Repo, []},
      {Core.BlockRepo, []},
      {Core.EventManagerRepo, []}
    ]

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
