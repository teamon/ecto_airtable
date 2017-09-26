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

  test "filter in_stock: true" do
    assert furnitures = Furniture |> where(in_stock: true) |> Repo.all()
    assert length(furnitures) == 14
    assert %Furniture{in_stock: true} = hd(furnitures)
  end

  test "filter in_stock: false" do
    assert furnitures = Furniture |> where(in_stock: false) |> Repo.all()
    assert length(furnitures) == 6
    assert %Furniture{in_stock: nil} = hd(furnitures)
  end

  test "filter type: Sofas" do
    assert furnitures = Furniture |> where(type: "Sofas") |> Repo.all()
    assert length(furnitures) == 1
    assert %Furniture{type: "Sofas"} = hd(furnitures)
  end

  test "filter type: Chairs, in_stock: true" do
    assert furnitures = Furniture |> where(type: "Chairs", in_stock: true) |> Repo.all()
    assert length(furnitures) == 3
    assert %Furniture{type: "Chairs", in_stock: true} = hd(furnitures)
  end

  test "filter type in Rugs, Tables" do
    types = ["Rugs", "Tables"]
    assert furnitures = Furniture |> where([f], f.type in ^types) |> Repo.all()
    assert length(furnitures) == 9
  end
end
