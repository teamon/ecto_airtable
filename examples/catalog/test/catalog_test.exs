defmodule CatalogTest do
  use ExUnit.Case

  alias Catalog.Repo
  alias Catalog.Furniture

  test "get all furniture" do
    assert furnitures = Furniture |> Repo.all()
    assert length(furnitures) == 20
    assert %Furniture{} = hd(furnitures)
  end
end
