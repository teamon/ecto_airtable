defmodule Catalog.Client do
  use Ecto.Schema

  @primary_key {:id, :string, []}
  schema "Clients" do
    field :name, :string
    field :notes, :string
  end
end
