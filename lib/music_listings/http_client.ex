defmodule MusicListings.HttpClient do
  @moduledoc """
  Just a wrapper to make swapping out HttpClient easier if need to do this
  again in the future.  i.e. an issue with brotli decompression meant we
  needed to swap Req out until the associated erl brotli lib was fixed
  """
  defmodule Response do
    @moduledoc """
    Response structure for the HttpClient
    """
    @type t() :: %__MODULE__{status: non_neg_integer(), body: binary()}
    defstruct [:status, :body]

    @spec new(HTTPoison.Response.t()) :: t()
    def new(%{status_code: status, body: body}) do
      %__MODULE__{status: status, body: body}
    end

    @spec new(non_neg_integer(), binary()) :: t()
    def new(status, body) do
      %__MODULE__{status: status, body: body}
    end
  end

  @spec get(String.t(), list() | nil) :: {:ok, Response.t()} | {:error, HTTPoison.Error.t()}
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

  @spec post(String.t(), String.t(), list() | nil) ::
          {:ok, Response.t()} | {:error, HTTPoison.Error.t()}
  def post(url, body, headers) do
    url
    |> HTTPoison.post(body, headers)
    |> case do
      {:ok, response} -> {:ok, Response.new(response)}
      {:error, error} -> {:error, error}
    end
  end
end
