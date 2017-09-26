# Ecto adapter for Airtable

**THIS ISN'T EVEN ALPHA, USE AT YOUR VERY OWN RISK!**


## Installation

```elixir
def deps do
  [
    {:ecto_airtable, "~> 0.1.0"}
  ]
end
```

## Configuration

```elixir
# config/config.exs

config :myapp, MyApp.Repo,
  adapter: Ecto.Adapter.Airtable,
  api_key: "your-api-key",
  base_id: "base-id"

```

## Credits

Huge thanks to @wojtekmach for [github_ecto](https://github.com/wojtekmach/github_ecto)
