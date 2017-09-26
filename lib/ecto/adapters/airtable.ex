defmodule Ecto.Adapters.Airtable do
  defmodule Number do
    @behaviour Ecto.Type
    def type, do: __MODULE__
    def cast(num), do: {:ok, num}
    def load(num), do: {:ok, num}
    def dump(num), do: {:ok, num}
  end

  defmodule Attachments do
    @behaviour Ecto.Type

    def type, do: __MODULE__

    def cast(num), do: {:ok, num}

    def load(attachments) do
      {:ok, Enum.map(attachments, &load_attachment/1)}
    end

    def dump(num), do: {:ok, num}

    defp load_attachment(attachment) do
      %{
        id:       attachment["id"],
        url:      attachment["url"],
        filename: attachment["filename"],
        size:     attachment["size"],
        type:     attachment["type"],
        width:    attachment["width"],
        height:   attachment["height"],
        thumbnails: %{
          small: load_thumbnail(attachment["thumbnails"]["small"]),
          large: load_thumbnail(attachment["thumbnails"]["large"])
        }
      }
    end

    defp load_thumbnail(thumb) do
      %{
        url:    thumb["url"],
        width:  thumb["width"],
        height: thumb["height"]
      }
    end
  end

  alias Ecto.Adapters.Airtable.Query
  alias Ecto.Adapters.Airtable.Connection

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
  def delete(_repo, %{source: {_, table}}, [id: id], _opts) do
    with :ok <- Connection.delete(table, id) do
      {:ok, []}
    end
  end

  @impl true
  def insert_all(repo, meta, _fields, list, on_conflict, returning, opts) do
    for item <- list do
      insert(repo, meta, item, on_conflict, returning, opts)
    end

    {length(list), nil}
  end

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
