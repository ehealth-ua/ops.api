defmodule :ops_tasks do
  @moduledoc false

  import Mix.Ecto, warn: false

  def migrate! do
    block_migrations_dir = Path.join(["priv", "block_repo", "migrations"])
    ops_migrations_dir = Path.join(["priv", "repo", "migrations"])

    load_app()

    ops_block_repo = OPS.BlockRepo
    ops_block_repo.start_link()

    Ecto.Migrator.run(ops_block_repo, block_migrations_dir, :up, all: true)

    repo = OPS.Repo
    repo.start_link()

    Ecto.Migrator.run(repo, ops_migrations_dir, :up, all: true)

    System.halt(0)
    :init.stop()
  end

  def check_consistency! do
    load_app()

    OPS.Repo.start_link()
    OPS.BlockRepo.start_link()

    result = OPS.Block.API.verify_chain_and_notify()
    IO.inspect result, label: "Verification result"

    System.halt(0)
    :init.stop()
  end

  def close_block! do
    load_app()

    OPS.Repo.start_link()
    OPS.BlockRepo.start_link()

    {:ok, block} = OPS.Block.API.close_block()
    IO.inspect block

    System.halt(0)
    :init.stop()
  end

  defp load_app do
    start_applications([:logger, :postgrex, :ecto, :hackney])
    :ok = Application.load(:ops)
  end

  defp start_applications(apps) do
    Enum.each(apps, fn app ->
      {_, _message} = Application.ensure_all_started(app)
    end)
  end
end
