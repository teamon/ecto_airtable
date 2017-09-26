defmodule CatalogTest do
  use ExUnit.Case

  alias Catalog.Repo
  alias Catalog.Furniture
  import Ecto.Query

  test "get all furniture" do
    assert furnitures = Furniture |> Repo.all()
    assert length(furnitures) == 20
    assert %Furniture{} = hd(furnitures)
  end

  test "get 5 furniture" do
    assert furnitures = Furniture |> limit(5) |> Repo.all()
    assert length(furnitures) == 5
    assert %Furniture{} = hd(furnitures)
  end
end
