defmodule MusicListings.HttpClient.Req do
  @moduledoc """
  Req HttpClient implementation
  """
  @behaviour MusicListings.HttpClient

  alias MusicListings.HttpClient.Response

  @impl true
  def get(url, headers \\ []) do
    url
    |> Req.get(headers)
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def post(url, body, headers) do
    url
    |> Req.post(headers: headers, json: body)
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end
end
