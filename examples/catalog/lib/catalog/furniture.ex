defmodule Catalog.Furniture do
  use Ecto.Schema

  @primary_key {:id, :string, []}
  schema "Furniture" do
    field :name, :string
    field :in_stock, :boolean
  end
end
