defmodule Ecto.Adapters.Airtable.Query do
  def params(query, [{:&, [], [0, names, _]}], params) do
    %{
      "filterByFormula" => where(query, params),
      "fields" => fields(names),
      "limit" => limit(query)
    }
    |> Enum.filter(fn {_,v} -> v end)
  end

  def limit(%Ecto.Query{limit: %Ecto.Query.QueryExpr{expr: expr}}), do: expr(expr, [])
  def limit(_), do: nil

  defp fields(names), do: Enum.map(names -- [:id], &space_camel/1)

  def where(query, params \\ [])
  def where(%Ecto.Query{wheres: []}, _), do: nil
  def where(%Ecto.Query{wheres: wheres}, params) do
    case Enum.map(wheres, fn where -> expr(where.expr, where.params || params) end) do
      [one] -> one
      many -> fun("AND", many)
    end
  end

  defp expr({:==, [], [lhs, rhs]}, params) do
    eq(expr(lhs, params), expr(rhs, params))
  end

  defp expr({:!=, [], [lhs, rhs]}, params) do
    expr(lhs, params) <> " != " <> expr(rhs, params)
  end

  defp expr({:>, [], [lhs, rhs]}, params) do
    expr(lhs, params) <> " > " <> expr(rhs, params)
  end

  defp expr({:>=, [], [lhs, rhs]}, params) do
    expr(lhs, params) <> " >= " <> expr(rhs, params)
  end

  defp expr({:<, [], [lhs, rhs]}, params) do
    expr(lhs, params) <> " < " <> expr(rhs, params)
  end

  defp expr({:<=, [], [lhs, rhs]}, params) do
    expr(lhs, params) <> " <= " <> expr(rhs, params)
  end

  defp expr({:and, [], [lhs, rhs]}, params) do
    fun("AND", [expr(lhs, params), expr(rhs, params)])
  end

  defp expr({:or, [], [lhs, rhs]}, params) do
    fun("OR", [expr(lhs, params), expr(rhs, params)])
  end

  defp expr({:not, [], [lhs]}, params) do
    fun("NOT", [expr(lhs, params)])
  end

  defp expr({:is_nil, [], [lhs]}, params) do
    expr(lhs, params) <> " = BLANK()"
  end

  defp expr({:fragment, [], parts}, params) do
    Enum.map_join(parts, &expr(&1, params))
  end

  defp expr({:raw, raw}, _) do
    raw
  end

  defp expr({:expr, expr}, params) do
    expr(expr, params)
  end

  defp expr({expr, _type}, params) do
    expr(expr, params)
  end

  defp expr({{:., _, [{:&, _, [_idx]}, field]}, _, []}, _) do
    "{" <> space_camel(field) <> "}"
  end

  defp expr({:in, [], [_lhs, []]}, _params) do
    "FALSE()"
  end

  defp expr({:in, [], [lhs, rhs]}, params)do
    field = expr(lhs, params)
    case expr(rhs, params) do
      [] ->
        "FALSE()"
      [_|_] = list ->
        args  = Enum.map(list, &eq(field, &1))
        fun("OR", args)
      exp when is_binary(exp) ->
        eq(field, exp)
    end
  end

  defp expr({:^, [], [i]}, params) do
    expr(Enum.at(params, i), params)
  end

  defp expr({:^, [], [i,n]}, params) do
    params
    |> Enum.slice(i, n)
    |> Enum.map(&expr(&1, params))
  end

  defp expr(%Ecto.Query.Tagged{type: _type, value: value}, params) do
    expr(value, params)
  end

  defp expr(true, _), do: "TRUE()"
  defp expr(false, _), do: "FALSE()"

  defp expr(bin, _) when is_binary(bin), do: ~s|"#{bin}"|
  defp expr(num, _) when is_number(num), do: to_string(num)

  defp expr(list, params) when is_list(list) do
    Enum.map(list, &expr(&1, params))
  end

  defp fun(f, args) do
    "#{f}(" <> Enum.join(args, ",") <> ")"
  end

  defp eq(lhs, rhs) do
    lhs <> " = " <> rhs
  end

  def space_camel(key) do
    key
    |> to_string
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
