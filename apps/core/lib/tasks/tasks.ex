defmodule Core.ReleaseTasks do
  @moduledoc false

  import Mix.Ecto, warn: false
  alias Ecto.Migrator

  @repo Core.Repo
  @block_repo Core.BlockRepo

  def migrate do
    block_migrations_dir = Application.app_dir(:core, "priv/block_repo/migrations")
    migrations_dir = Application.app_dir(:core, "priv/repo/migrations")

    @repo
    |> start_repo()
    |> Migrator.run(migrations_dir, :up, all: true)

    @block_repo
    |> start_repo()
    |> Migrator.run(block_migrations_dir, :up, all: true)

    System.halt(0)
    :init.stop()
  end

  def check_consistency do
    start_repo(@repo)
    start_repo(@block_repo)

    result = Core.Block.API.verify_chain_and_notify()
    IO.inspect(result, label: "Verification result")

    System.halt(0)
    :init.stop()
  end

  def close_block do
    start_repo(@repo)
    start_repo(@block_repo)

    {:ok, block} = Core.Block.API.close_block()
    IO.inspect(block)

    System.halt(0)
    :init.stop()
  end

  defp start_repo(repo) do
    start_applications([:logger, :postgrex, :ecto, :ecto_sql, :hackney])
    Application.load(:core)
    repo.start_link()
    repo
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_, _message} = Application.ensure_all_started(app)
    end)
  end
end
