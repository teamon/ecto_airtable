defmodule CatalogTest do
  use ExUnit.Case

  alias Catalog.Repo
  alias Catalog.Furniture

  test "greets the world" do
    assert furnitures = Repo.all(Furniture)
    assert length(furnitures) == 5
    assert %Furniture{} = hd(furnitures)
  end
end
