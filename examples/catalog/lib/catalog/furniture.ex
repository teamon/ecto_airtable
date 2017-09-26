defmodule Catalog.Furniture do
  use Ecto.Schema

  schema "Furniture" do
    field :name, :string
    field :in_stock, :boolean
    timestamps
  end
end
