defmodule Ecto.Adapters.Airtable.Client do
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
