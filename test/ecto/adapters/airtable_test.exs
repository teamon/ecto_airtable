defmodule Ecto.Adapters.AirtableTest do
  use ExUnit.Case

  import Ecto.Query

  defmodule Schema do
    use Ecto.Schema

    schema "Test" do
      field :x, :integer
      field :y, :string
    end
  end

  defp filter(query), do: Ecto.Adapters.Airtable.Query.where(query)
  defp limit(query), do: Ecto.Adapters.Airtable.Query.limit(query)

  describe "Query" do
    # based on https://github.com/elixir-ecto/ecto/blob/master/test/ecto/adapters/postgres_test.exs

    test "limit and offset" do
      query = Schema |> limit([r], 3)
      assert limit(query) == "3"
    end

    test "binary ops" do
      query = Schema |> where([r], r.x == 2)
      assert filter(query) == "{X} = 2"

      query = Schema |> where([r], r.x != 2)
      assert filter(query) == "{X} != 2"

      query = Schema |> where([r], r.x <= 2)
      assert filter(query) == "{X} <= 2"

      query = Schema |> where([r], r.x >= 2)
      assert filter(query) == "{X} >= 2"

      query = Schema |> where([r], r.x < 2)
      assert filter(query) =="{X} < 2"

      query = Schema |> where([r], r.x > 2)
      assert filter(query) == "{X} > 2"
    end

    test "is_nil" do
      query = Schema |> where([r], is_nil(r.x))
      assert filter(query) == "{X} = BLANK()"

      query = Schema |> where([r], not is_nil(r.x))
      assert filter(query) == "NOT({X} = BLANK())"
    end

    test "fragments" do
      query = Schema |> where([r], fragment("now") == 1)
      assert filter(query) == "now = 1"

      query = Schema |> where([r], fragment("LOWER(?)", r.x) == 1)
      assert filter(query) == "LOWER({X}) = 1"

      value = 13
      query = Schema |> where([r], fragment("LEFT(?, ?)", r.x, ^value) == 1)
      assert filter(query) == "LEFT({X}, 13) = 1"
    end

    test "literals" do
      query = "schema" |> where(foo: true)
      assert filter(query) == "{Foo} = TRUE()"

      query = "schema" |> where(foo: false)
      assert filter(query) == "{Foo} = FALSE()"

      query = "schema" |> where(foo: "abc")
      assert filter(query) == "{Foo} = \"abc\""

      query = "schema" |> where(foo: <<0,?a,?b,?c>>)
      assert filter(query) == "{Foo} = \"#{<<0,?a,?b,?c>>}\""

      query = "schema" |> where(foo: 123)
      assert filter(query) == "{Foo} = 123"

      query = "schema" |> where(foo: 123.0)
      assert filter(query) == "{Foo} = 123.0"
    end

    test "nested expressions" do
      z = 123
      query = Schema |> where([r], r.x > 0 and (r.y > ^z) or true)
      assert filter(query) == "OR(AND({X} > 0,{Y} > 123),TRUE())"
    end

    test "in expression" do
      query = Schema |> where([e], 1 in [])
      assert filter(query) == "FALSE()"

      query = Schema |> where([e], 1 in [1, e.x, 3])
      assert filter(query) == "OR(1 = 1,1 = {X},1 = 3)"

      query = Schema |> where([e], 1 in ^[])
      assert filter(query) == "FALSE()"

      query = Schema |> where([e], 1 in ^[1, 2, 3])
      assert filter(query) == "OR(1 = 1,1 = 2,1 = 3)"

      query = Schema |> where([e], 1 in [1, ^2, 3])
      assert filter(query) == "OR(1 = 1,1 = 2,1 = 3)"

      query = Schema |> where([e], ^1 in [1, ^2, 3])
      assert filter(query) == "OR(1 = 1,1 = 2,1 = 3)"

      query = Schema |> where([e], ^1 in ^[1, 2, 3])
      assert filter(query) == "OR(1 = 1,1 = 2,1 = 3)"

      query = Schema |> where([e], 1 in e.x)
      assert filter(query) == "1 = {X}"

      query = Schema |> where([e], 1 in fragment("foo"))
      assert filter(query) == "1 = foo"
    end
  end
end
