defmodule OPS.EventManagerRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :ops
  use EctoTrail
end
