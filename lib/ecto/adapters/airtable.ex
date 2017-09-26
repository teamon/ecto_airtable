defmodule Ecto.Adapters.Airtable do
  defmodule Client do
    use Tesla

    plug Tesla.Middleware.JSON
    plug Tesla.Middleware.Logger

    def new(base, api_key) do
      Tesla.build_client [
        {Tesla.Middleware.BaseUrl, "https://api.airtable.com/v0/#{base}/"},
        {Tesla.Middleware.Headers, %{"Authorization" => "Bearer #{api_key}"}}
      ]
    end

    def all(client, table, params) do
      case get(client, table, query: params) do
        %{status: 200, body: %{"records" => records}} -> {:ok, records}
        env -> {:error, env}
      end
    end
  end


  defmodule Connection do
    use GenServer

    alias Ecto.Adapters.Airtable.Client

    ## CLIENT API

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

    def all(table, params) do
      GenServer.call(__MODULE__, {:all, table, params})
    end

    ## CALLBACKS

    def init(opts) do
      {:ok, Client.new(opts[:base_id], opts[:api_key])}
    end

    def handle_call({:all, table, params}, _from, client) do
      reply = Client.all(client, table, params)
      {:reply, reply, client}
    end
  end


  defmodule Number do
    @behaviour Ecto.Type
    def type, do: __MODULE__
    def cast(num), do: {:ok, num}
    def load(num), do: {:ok, num}
    def dump(num), do: {:ok, num}
  end


  defmodule Query do
    def params(query, [{:&, [], [0, names, _]}], params) do
      %{}
      |> Map.merge(where(query, params))
      |> Map.merge(fields(names))
      |> Map.merge(limit(query))
    end

    defp limit(%Ecto.Query{limit: %Ecto.Query.QueryExpr{expr: expr}}), do: %{"pageSize" => expr}
    defp limit(_), do: %{}

    defp fields(names), do: %{"fields" => Enum.map(names -- [:id], &space_camel/1)}

    defp where(%Ecto.Query{wheres: []}, _), do: %{}
    defp where(%Ecto.Query{wheres: wheres} = query, params) do
      formula = case Enum.map(wheres, fn where -> expr(where.expr, where.params || params) end) do
        [one] -> one
        many -> fun("AND", many)
      end

      IO.puts formula

      %{"filterByFormula" => formula}
    end

    defp expr({:==, [], [lhs, rhs]}, params) do
      expr(lhs, params) <> " = " <> expr(rhs, params)
    end

    defp expr({:>, [], [lhs, rhs]}, params) do
      expr(lhs, params) <> " > " <> expr(rhs, params)
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

    defp expr({{:., _, [{:&, _, [_idx]}, field]}, _, []}, _) do
      "{" <> space_camel(field) <> "}"
    end

    defp expr({:in, [], [lhs, rhs]}, params) do
      field = expr(lhs, params)
      args  = Enum.map(expr(rhs, params), &(field <> " = " <> &1))
      fun("OR", args)
    end

    defp expr({:^, [], [i]}, params) do
      expr(Enum.at(params, i), params)
    end

    defp expr({:^, [], [i,n]}, params) do
      params
      |> Enum.slice(i, n)
      |> Enum.map(&expr(&1, params))
    end

    defp expr(lit, _) when is_binary(lit) or is_number(lit), do: inspect(lit)

    defp expr(true, _), do: "TRUE()"
    defp expr(false, _), do: "FALSE()"

    defp fun(f, args) do
      "#{f}(" <> Enum.join(args, ",") <> ")"
    end

    def space_camel(key) do
      key
      |> to_string
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")
    end
  end


  @behaviour Ecto.Adapter

  def __before_compile__(env), do: :ok

  def child_spec(repo, opts) do
    Supervisor.Spec.worker(Connection, [opts])
  end

  def loaders(primitive, _type), do: [primitive]

  def dumpers(primitive, _type), do: [primitive]

  def prepare(operation, query), do: {:nocache, {operation, query}}

  def execute(_repo,  %{fields: fields, sources: {{table, schema}}},
                      {:nocache, {:all, query}},
                      params, mapper, opts) do
    {:ok, records} = Connection.all(table, Query.params(query, fields, params))
    results = Enum.map(records, &convert(&1, fields, mapper))
    {length(results), results}
  end

  defp convert(record, [{:&, [], [0, fields, _]} = fd], mapper) do
    values = Enum.map(fields, &get_field(record, &1))
    [mapper.(fd, values, nil)]
  end

  defp get_field(record, :id), do: record["id"]
  defp get_field(record, field), do: record["fields"][Query.space_camel(field)]
end
