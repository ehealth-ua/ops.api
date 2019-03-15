defmodule OPS.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :ops
  alias Confex.Resolver

  # # Allow acceptance tests to run in concurrent mode
  # if Application.get_env(:ops, :sql_sandbox) do
  #   plug(Phoenix.Ecto.SQL.Sandbox)
  # end

  plug(Plug.RequestId)
  plug(EView.Plugs.Idempotency)
  plug(EhealthLogger.Plug, level: Logger.level())

  plug(EView)

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(OPS.Web.Router)

  def init(_key, config) do
    config = Resolver.resolve!(config)

    unless config[:secret_key_base] do
      raise "Set SECRET_KEY environment variable!"
    end

    {:ok, config}
  end
end
