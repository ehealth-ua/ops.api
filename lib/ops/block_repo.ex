defmodule OPS.BlockRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :ops
  alias Confex.Resolver

  def init(_, config) do
    config = Resolver.resolve!(config)

    unless config[:database] do
      raise "Set BLOCK_DB_NAME environment variable!"
    end

    unless config[:username] do
      raise "Set BLOCK_DB_USER environment variable!"
    end

    unless config[:password] do
      raise "Set BLOCK_DB_PASSWORD environment variable!"
    end

    unless config[:hostname] do
      raise "Set BLOCK_DB_HOST environment variable!"
    end

    unless config[:port] do
      raise "Set BLOCK_DB_PORT environment variable!"
    end

    {:ok, config}
  end
end
