defmodule OPS.Application do
  @moduledoc false

  use Application
  alias OPS.Web.Endpoint

  def start(_type, _args) do
    children = [Endpoint]

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
