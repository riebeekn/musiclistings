defmodule MusicListings.HttpClient.Req do
  @moduledoc """
  Req HttpClient implementation
  """
  @behaviour MusicListings.HttpClient

  alias MusicListings.HttpClient.Response

  @retry_statuses [403, 408, 429, 500, 502, 503, 504]

  @impl true
  def get(url, headers \\ []) do
    url
    |> Req.get(
      headers: headers,
      finch: MusicListings.ReqFinch,
      receive_timeout: 30_000,
      retry: &retry?/2,
      max_retries: 3
    )
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def post(url, body, headers) do
    url
    |> Req.post(
      headers: headers,
      json: body,
      finch: MusicListings.ReqFinch,
      receive_timeout: 30_000,
      retry: &retry?/2,
      max_retries: 3
    )
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end

  defp retry?(_request, %{status: status}) when status in @retry_statuses, do: true
  defp retry?(_request, %Req.TransportError{}), do: true
  defp retry?(_request, _response), do: false
end
