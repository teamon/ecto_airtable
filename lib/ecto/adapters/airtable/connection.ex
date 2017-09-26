defmodule Ecto.Adapters.Airtable.Connection do
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

  def delete(table, id) do
    GenServer.call(__MODULE__, {:delete, table, id})
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

  @impl true
  def handle_call({:delete, table, id}, _from, client) do
    reply = Client.del(client, table, id)
    {:reply, reply, client}
  end
end
