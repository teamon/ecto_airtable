# Ecto adapter for [Airtable](https://airtable.com/)

**THIS IS EARLY STAGE ALPHA SOFTWARE, USE AT YOUR VERY OWN RISK!**


## Installation

```elixir
def deps do
  [
    {:ecto_airtable, github: "teamon/ecto_airtable"}
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

## Usage

See [examples/catalog] for example usage.

## Credits

Huge thanks to @wojtekmach for [github_ecto](https://github.com/wojtekmach/github_ecto)


## Progress
- [x] Repo.all
- [x] Repo.insert
- [x] Repo.update
- [x] Repo.delete
- [x] Repo.get
- [x] Repo.get_by
- [x] Repo.insert_all
- [ ] Persistent HTTP connections pool
- [ ] Complex field types
  - [x] Attachments
  - [ ] Relations - Link to another record
- [ ] Embedded schemas
- [ ] Proper support for multiple repos
