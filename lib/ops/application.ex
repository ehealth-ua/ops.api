defmodule OPS do
  @moduledoc """
  This is an entry point of ops application.
  """
  use Application
  alias OPS.Web.Endpoint
  alias Confex.Resolver
  alias OPS.Scheduler

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(OPS.Repo, []),
      supervisor(OPS.BlockRepo, []),
      supervisor(OPS.EventManagerRepo, []),
      # Start the endpoint when the application starts
      supervisor(OPS.Web.Endpoint, []),
      # Starts a worker by calling: OPS.Worker.start_link(arg1, arg2, arg3)
      # worker(OPS.Worker, [arg1, arg2, arg3]),

      worker(
        OPS.DeclarationsAutoProcessor,
        [:declaration_terminator],
        id: :declaration_terminator
      ),
      worker(OPS.DeclarationsAutoProcessor, [:declaration_approver], id: :declaration_approver),
      worker(OPS.Scheduler, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OPS.Supervisor]
    result = Supervisor.start_link(children, opts)
    Scheduler.create_jobs()
    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  # Loads configuration in `:init` callbacks and replaces `{:system, ..}` tuples via Confex
  @doc false
  def init(_key, config) do
    Resolver.resolve(config)
  end
end
