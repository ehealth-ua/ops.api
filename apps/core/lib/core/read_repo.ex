defmodule Core.ReadRepo do
  @moduledoc false

  @paginator_options [page_size: 50, max_page_size: 300]

  use Ecto.Repo, otp_app: :core, adapter: Ecto.Adapters.Postgres
  use EctoTrail
  use Scrivener, @paginator_options

  alias Scrivener.Config

  def paginator_options(options \\ []) do
    Config.new(__MODULE__, @paginator_options, options)
  end
end
