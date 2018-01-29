defmodule OPS.Repo do
  @moduledoc """
  Repo for Ecto database.

  More info: https://hexdocs.pm/ecto/Ecto.Repo.html
  """
  use Ecto.Repo, otp_app: :ops
  use EctoTrail
  use Scrivener, page_size: 50
end
