defmodule EctoAirtable.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ecto_airtable,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.1.4"},
      {:tesla, github: "teamon/tesla"},
      {:hackney, "~> 1.9.0"},
      {:poison, "~> 2.0"},

      {:mix_test_watch, "~> 0.5.0", only: :dev}
    ]
  end
end
