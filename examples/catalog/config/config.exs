use Mix.Config

config :catalog, Catalog.Repo,
  adapter: Ecto.Adapters.Airtable,
  api_key: "",
  base_id: ""
