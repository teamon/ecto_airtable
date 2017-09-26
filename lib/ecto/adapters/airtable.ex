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

    def all(client, table, query) do
      case get(client, table, query: query) do
        %{status: 200, body: %{"records" => records}} -> {:ok, records}
        env -> {:error, env}
      end
    end

    def find(client, table, id) do
      case get(client, path(table, id)) do
        %{status: 200, body: record} -> {:ok, record}
        %{status: 404} -> {:error, :not_found}
        env -> {:error, env}
      end
    end

    def insert(client, table, fields) do
      case post(client, table, %{"fields" => fields}) do
        %{status: 200, body: record} -> {:ok, record}
        env -> {:error, env}
      end
    end

    def update(client, table, id, fields) do
      case patch(client, path(table, id), %{"fields" => fields}) do
        %{status: 200, body: record} -> {:ok, record}
        env -> {:error, env}
      end
    end

    defp path(table, id), do: table <> "/" <> id
  end


  defmodule Connection do
    use GenServer

    alias Ecto.Adapters.Airtable.Client

    ## CLIENT API

    def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

    def all(table, params) do
      GenServer.call(__MODULE__, {:all, table, params})
    end

    def find(table, id) do
      GenServer.call(__MODULE__, {:find, table, id})
    end

    def insert(table, params) do
      GenServer.call(__MODULE__, {:insert, table, params})
    end

    def update(table, id, params) do
      GenServer.call(__MODULE__, {:update, table, id, params})
    end

    ## CALLBACKS

    @impl true
    def init(opts) do
      {:ok, Client.new(opts[:base_id], opts[:api_key])}
    end

    @impl true
    def handle_call({:all, table, params}, _from, client) do
      reply = Client.all(client, table, params)
      {:reply, reply, client}
    end

    @impl true
    def handle_call({:find, table, id}, _from, client) do
      reply = Client.find(client, table, id)
      {:reply, reply, client}
    end

    @impl true
    def handle_call({:insert, table, params}, _from, client) do
      reply = Client.insert(client, table, params)
      {:reply, reply, client}
    end

    @impl true
    def handle_call({:update, table, id, params}, _from, client) do
      reply = Client.update(client, table, id, params)
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


  @behaviour Ecto.Adapter

  @impl true
  defmacro __before_compile__(_env), do: :ok

  @impl true
  def child_spec(_repo, opts) do
    Supervisor.Spec.worker(Connection, [opts])
  end

  @impl true
  def ensure_all_started(_repo, _type), do: {:ok, []}

  @impl true
  def loaders(primitive, _type), do: [primitive]

  @impl true
  def dumpers(primitive, _type), do: [primitive]

  @impl true
  def prepare(operation, query), do: {:nocache, {operation, query}}

  @impl true
  def autogenerate(_), do: ""

  @impl true
  def insert(_repo, %{source: {_, table}}, fields, _on_conflict, _returning, _opts) do
    with {:ok, record} <- Connection.insert(table, attrs(fields)) do
      {:ok, convert(record, [:id | Keyword.keys(fields)])}
    end
  end

  @impl true
  def update(_repo, %{source: {_, table}}, fields, filters, _returning, _opts) do
    id = Keyword.fetch!(filters, :id)
    with {:ok, record} <- Connection.update(table, id, attrs(fields)) do
      {:ok, convert(record, [:id | Keyword.keys(fields)])}
    end
  end

  @impl true
  def delete(_, _, _, _), do: raise "Not Yet Implemented"

  @impl true
  def insert_all(_, _, _, _, _, _, _), do: raise "Not Yet Implemented"

  @impl true
  def execute(_repo,
    %{fields: fields, sources: {{table, _schema}}},
    {:nocache, {:all, %Ecto.Query{wheres: [
      %Ecto.Query.BooleanExpr{expr: {:==, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}, {:^, [], [0]}]}}]
    }}},
    [id], mapper, _opts)
  do
    case Connection.find(table, id) do
      {:ok, record} ->
        {1, [convert(record, fields, mapper)]}
      {:error, :not_found} ->
        {0, []}
    end
  end

  @impl true
  def execute(_repo,  %{fields: fields, sources: {{table, _schema}}},
                      {:nocache, {:all, query}},
                      params, mapper, _opts) do
    {:ok, records} = Connection.all(table, Query.params(query, fields, params))
    results = Enum.map(records, &convert(&1, fields, mapper))
    {length(results), results}
  end

  defp convert(record, [{:&, [], [0, fields, _]} = fd], mapper) do
    values = Enum.map(fields, &get_field(record, &1))
    [mapper.(fd, values, nil)]
  end

  defp convert(record, fields) do
    fields
    |> Enum.map(&{&1, get_field(record, &1)})
  end

  defp get_field(record, :id), do: record["id"]
  defp get_field(record, field), do: record["fields"][Query.space_camel(field)]

  defp attrs(fields) do
    Enum.into(fields, %{}, fn {field, value} -> {Query.space_camel(field), value} end)
  end
end
