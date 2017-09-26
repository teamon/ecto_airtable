defmodule CatalogTest do
  use ExUnit.Case

  alias Catalog.Repo
  alias Catalog.Furniture
  alias Catalog.Client
  alias Catalog.Vendor

  import Ecto.Query
  import Ecto.Changeset

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

  test "filter unit_cost > 1000" do
    assert furnitures = Furniture |> where([f], f.unit_cost > 1000) |> Repo.all()
    assert length(furnitures) == 12
  end

  test "filter notes not empty" do
    assert furnitures = Furniture |> where([f], not(is_nil(f.notes))) |> Repo.all()
    assert length(furnitures) == 2
  end

  test "filter name starts with B" do
    assert furnitures = Furniture |> where([f], fragment(~S|LEFT(?, 1) = "B"|, f.name)) |> Repo.all()
    assert length(furnitures) == 4
  end

  test "load attachment field" do
    shelf = Repo.get(Furniture, "recXxbKyrgyYwDvcN")
    assert length(shelf.picture) == 5
    assert [picture | _] = shelf.picture
    assert is_binary(picture.url)
    assert is_binary(picture.thumbnails.small.url)
    assert is_binary(picture.thumbnails.large.url)
  end

  test "insert attachments" do
    vendor = %Vendor{
      name: "Tymon",
      logo: [
        %{url: "http://teamon.eu/assets/images/me.jpg"}
      ]
    }
    assert {:ok, vendor} = Repo.insert(vendor)

    # reload since Airtable does not immidiately return thumbs info
    vendor = Repo.get(Vendor, vendor.id)
    assert vendor.id != nil
    assert vendor.name == "Tymon"
    assert hd(vendor.logo).thumbnails.small.url != nil
  end

  test "get by id" do
    client = Client |> Repo.get("recYwiKKzloXywr4C")
    assert client.id != nil
    assert client.name == "Abbey Realty"
  end

  test "get_by id" do
    client = Client |> Repo.get_by(id: "recYwiKKzloXywr4C")
    assert client.id != nil
    assert client.name == "Abbey Realty"
  end

  test "get_by name" do
    client = Client |> Repo.get_by(name: "Abbey Realty")
    assert client.id != nil
    assert client.name == "Abbey Realty"
  end

  test "insert Client" do
    assert {:ok, client} = %Client{name: "Google", notes: "Cool"} |> Repo.insert
    assert client.id != nil
    assert client.name == "Google"
    assert client.notes == "Cool"
  end

  test "update Client" do
    client = Client |> where(name: "Abbey Realty") |> Repo.one
    assert {:ok, client} = client |> change(notes: "Wow") |> Repo.update
    assert client.notes == "Wow"
  end

  test "delete Client" do
    assert {:ok, client} = %Client{name: "Google", notes: "Cool"} |> Repo.insert
    assert {:ok, _} = client |> Repo.delete

    refute Repo.get(Client, client.id)
  end

  test "insert_all" do
    Repo.insert_all Client, [
      [name: "Amazon"],
      [name: "Wallmart"]
    ]
  end
end
