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
        case decode_body(response) do
          {:ok, body} -> {:ok, Response.new(response.status_code, body)}
          :passthrough -> {:ok, Response.new(response)}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  # Decodes the response body based on its Content-Encoding header (matched
  # case-insensitively). Returns `{:ok, decoded_body}` when decompression was
  # applied, or `:passthrough` to use the response body as-is.
  defp decode_body(response) do
    response.headers
    |> Enum.find_value(fn {name, value} ->
      if String.downcase(name) == "content-encoding", do: String.downcase(value)
    end)
    |> case do
      "br" ->
        {:ok, body} = :brotli.decode(response.body)
        {:ok, body}

      gzip when gzip in ["gzip", "x-gzip"] ->
        {:ok, :zlib.gunzip(response.body)}

      _other ->
        :passthrough
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
