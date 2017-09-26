defmodule Catalog.Furniture do
  use Ecto.Schema

  @primary_key {:id, :string, []}
  schema "Furniture" do
    field :name, :string
    field :type, :string
    field :unit_cost, Ecto.Adapters.Airtable.Number
    field :in_stock, :boolean
  end
end
