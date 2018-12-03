# Since configuration is shared in umbrella projects, this file
# should only configure the :ops application itself
# and only for organization purposes. All other config goes to
# the umbrella root.
use Mix.Config

config :ops, OPS.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4LcL78vtzM1yVeVCuY1351HuU/62qpTtDKykdJxAKKgwnTtH5JzkXNEUouzDBc1D",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

config :phoenix, json_library: Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
