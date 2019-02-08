defmodule Core.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
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
