defmodule EventuallyInconsistentPg.MixProject do
  use Mix.Project

  def project do
    [
      app: :eventually_inconsistent_pg,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {EventuallyInconsistentPg.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_unit_cluster, "~> 0.1.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
