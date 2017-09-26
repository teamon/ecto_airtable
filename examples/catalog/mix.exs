defmodule Catalog.Mixfile do
  use Mix.Project

  def project do
    [
      app: :catalog,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Catalog.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_airtable, path: "../.."},
      {:mix_test_watch, "~> 0.5.0", only: :dev}
    ]
  end
end
