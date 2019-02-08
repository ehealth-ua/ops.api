defmodule OpsScheduler.Application do
  @moduledoc false

  use Application
  alias OpsScheduler.Worker

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Worker, []}
    ]

    opts = [strategy: :one_for_one, name: OpsScheduler.Supervisor]
    result = Supervisor.start_link(children, opts)
    Worker.create_jobs()
    result
  end
end
