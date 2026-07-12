defmodule MusicListings.HttpClient do
  @moduledoc """
  Specification for the HttpClient.  MusicListings.HttpClient.Req makes the
  real requests, MusicListings.HttpClient.Test serves local fixtures.

  Configured in config.exs by:
    config :music_listings, :http_client, MusicListings.HttpClient.Req
  """
  defmodule Response do
    @moduledoc """
    Response structure for the HttpClient
    """
    @type t() :: %__MODULE__{status: non_neg_integer(), body: binary()}
    defstruct [:status, :body]

    @spec new(Req.Response.t()) :: t()
    def new(%{status: status, body: body}) do
      %__MODULE__{status: status, body: body}
    end

    @spec new(non_neg_integer(), binary()) :: t()
    def new(status, body) do
      %__MODULE__{status: status, body: body}
    end
  end

  @doc """
  Callback invoked on a get
  """
  @callback get(url :: String.t(), headers :: list() | nil) ::
              {:ok, Response.t()} | {:error, any()}

  @doc """
  Client specific get
  """
  def get(url, headers \\ []) do
    http_client().get(url, headers)
  end

  @doc """
  Callback invoked on a post
  """
  @callback post(url :: String.t(), body :: String.t(), headers :: list() | nil) ::
              {:ok, Response.t()} | {:error, any()}

  @doc """
  Client specific post
  """
  def post(url, body, headers) do
    http_client().post(url, body, headers)
  end

  defp http_client do
    Application.fetch_env!(:music_listings, :http_client)
  end
end
