defmodule Catalog.Vendor do
  use Ecto.Schema

  @primary_key {:id, :string, []}
  schema "Vendors" do
    field :name, :string
    field :logo, Ecto.Adapters.Airtable.Attachments
  end
end
