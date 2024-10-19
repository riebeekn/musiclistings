defmodule MusicListings.HttpClient.HTTPoison do
  @moduledoc """
  HTTPoison HttpClient implementation
  """
  @behaviour MusicListings.HttpClient

  alias MusicListings.HttpClient.Response

  @impl true
  def get(url, headers \\ []) do
    url
    |> HTTPoison.get(headers)
    |> case do
      {:ok, response} ->
        response.headers
        |> Enum.find(&(&1 == {"Content-Encoding", "br"}))
        |> case do
          nil ->
            {:ok, Response.new(response)}

          _needs_decoding ->
            {:ok, body} = :brotli.decode(response.body)
            {:ok, Response.new(response.status_code, body)}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def post(url, body, headers) do
    body = Jason.encode!(body)

    url
    |> HTTPoison.post(body, headers)
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end
end
