defmodule Core.BlockRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :core, adapter: Ecto.Adapters.Postgres
end
