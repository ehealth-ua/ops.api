defmodule Ops.MixProject do
  @moduledoc false

  use Mix.Project

  @version "2.6.0"
  def project do
    [
      version: @version,
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      docs: [filter_prefix: "OPS.Rpc"]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:distillery, "~> 2.0", runtime: false, override: true},
      {:excoveralls, "~> 0.10.2", only: [:dev, :test]},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:git_ops, "~> 0.6.0", only: [:dev]}
    ]
  end
end
