defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      compilers: Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Core.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.4"},
      {:confex, "~> 3.3"},
      {:mox, "~> 0.4.0"},
      {:jason, "~> 1.1"},
      {:ecto, "~> 2.2"},
      {:ex_machina, "~> 2.2"},
      {:ecto_trail, "~> 0.2.4"},
      {:phoenix_ecto, "~> 3.6"},
      {:scrivener_ecto, "~> 1.3"},
      {:postgrex, ">= 0.0.0"},
      {:ecto_logger_json, git: "https://github.com/edenlabllc/ecto_logger_json.git", branch: "query_params"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": [
        "ecto.create",
        "ecto.create --repo Core.EventManagerRepo",
        "ecto.create --repo Core.BlockRepo",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: [
        "ecto.drop",
        "ecto.create --quiet",
        "ecto.create --quiet --repo Core.EventManagerRepo",
        "ecto.create --quiet --repo Core.BlockRepo",
        "ecto.migrate",
        "test"
      ]
    ]
  end
end
