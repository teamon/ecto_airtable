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
  adapter: Ecto.Adapters.Airtable,
  api_key: "your-api-key",
  base_id: "base-id"

```

## Credits

Huge thanks to @wojtekmach for [github_ecto](https://github.com/wojtekmach/github_ecto)


## Progress
- [x] Repo.all
- [x] Repo.insert
- [x] Repo.update
- [x] Repo.get
- [x] Repo.get_by
- [ ] Repo.insert_all
- [ ] Repo.update_all
