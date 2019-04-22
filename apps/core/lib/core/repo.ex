defmodule Core.Repo do
  @moduledoc false

  use Ecto.Repo, otp_app: :core, adapter: Ecto.Adapters.Postgres
  use EctoTrail

  use Scrivener,
    page_size: 50,
    max_page_size: Confex.fetch_env!(:core, :max_page_size),
    options: [allow_out_of_range_pages: true]
end
