defmodule MusicListings.Affiliates.TicketNetwork.Client do
  @moduledoc """
  Reads the TicketNetwork product catalog from the Impact.com Catalogs API.

  TicketNetwork publishes its inventory as an Impact.com catalog; we are an
  Impact media partner, so each catalog row carries our affiliate `Url`.  The
  API pages 100 items at a time and reports the page count in `@numpages`.

  Credentials come from `config :music_listings, :ticket_network` (set from the
  environment in `config/runtime.exs`).  Authentication is HTTP Basic with the
  account SID as the username and the auth token as the password.
  """
  alias MusicListings.Affiliates.TicketNetwork.Item
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers

  require Logger

  @base_url "https://api.impact.com/Mediapartners"

  # TicketNetwork's catalog id.  `Gtin` is the city field - see Item's docs for
  # the rest of the repurposed-field mapping.
  @catalog_id "1872"
  @query "Category = 'CONCERTS' AND Gtin = 'Toronto'"

  # Guards against a paging bug turning into an unbounded request loop; the
  # Toronto catalog runs to 8 pages, so this is a long way clear of normal.
  @max_pages 50

  # The Impact.com catalog is slow enough that the crawler's 30s default times
  # it out, so give it two minutes. One retry rather than the usual three: at
  # this timeout a hung catalog would otherwise hold up the crawl summary email
  # for the better part of an hour before we gave up on it.
  @request_opts [receive_timeout: :timer.minutes(2), max_retries: 1]

  @doc """
  Fetches every catalog item for Toronto concerts.

  Returns `{:error, reason}` if any page fails rather than a partial catalog -
  a short read would look like a batch of delisted events to the matcher and
  cause it to clear links that are still live.
  """
  @spec fetch_items(Date.t()) :: {:ok, [Item.t()]} | {:error, term()}
  def fetch_items(today \\ Date.utc_today()) do
    case config() do
      {:ok, credentials} -> fetch_pages(credentials, today, 1, [])
      :error -> {:error, :not_configured}
    end
  end

  @doc """
  Whether API credentials are configured.  They are absent in dev and test, and
  the caller skips the run rather than failing.
  """
  @spec configured? :: boolean()
  def configured? do
    match?({:ok, _credentials}, config())
  end

  defp fetch_pages(_credentials, _today, page, _acc) when page > @max_pages do
    {:error, :too_many_pages}
  end

  defp fetch_pages(credentials, today, page, acc) do
    url = page_url(credentials.account_sid, page)

    case HttpClient.get(url, headers(credentials), @request_opts) do
      {:ok, %HttpClient.Response{status: 200, body: body}} ->
        payload = ParseHelpers.maybe_decode!(body)
        items = payload |> Map.get("Items", []) |> parse_items(today)
        acc = acc ++ items

        if page < num_pages(payload) do
          fetch_pages(credentials, today, page + 1, acc)
        else
          {:ok, acc}
        end

      {:ok, %HttpClient.Response{status: status}} ->
        Logger.error("TicketNetwork catalog page #{page} returned status #{status}")
        {:error, {:unexpected_status, status}}

      {:error, reason} ->
        Logger.error("TicketNetwork catalog page #{page} failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp parse_items(rows, today) do
    rows
    |> Enum.map(&Item.new(&1, today))
    |> Enum.reject(&is_nil/1)
  end

  defp num_pages(payload) do
    case payload["@numpages"] do
      pages when is_integer(pages) -> pages
      pages when is_binary(pages) -> String.to_integer(pages)
      _other -> 1
    end
  end

  # Built from a list rather than a map so parameter order is stable.
  defp page_url(account_sid, page) do
    query = URI.encode_query([{"Query", @query}, {"Page", page}])

    "#{@base_url}/#{account_sid}/Catalogs/#{@catalog_id}/Items?#{query}"
  end

  defp headers(credentials) do
    encoded = Base.encode64("#{credentials.account_sid}:#{credentials.auth_token}")

    [
      {"accept", "application/json"},
      {"authorization", "Basic #{encoded}"}
    ]
  end

  defp config do
    config = Application.get_env(:music_listings, :ticket_network, [])
    account_sid = config[:account_sid]
    auth_token = config[:auth_token]

    if present?(account_sid) and present?(auth_token) do
      {:ok, %{account_sid: account_sid, auth_token: auth_token}}
    else
      :error
    end
  end

  defp present?(value), do: is_binary(value) and value != ""
end
