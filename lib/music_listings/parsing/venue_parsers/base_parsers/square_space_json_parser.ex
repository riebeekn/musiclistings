defmodule MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceJsonParser do
  @moduledoc """
  Base parser for SquareSpace venues that use JSON APIs with GetItemsByMonth endpoints
  """

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  # Ticket vendors seen linked from SquareSpace excerpts.  Matched as
  # substrings, so `eventbrite.` covers both the .com and .ca domains.
  @ticket_hosts [
    "eventbrite.",
    "ticketweb.",
    "tixr.com",
    "dice.fm",
    "showclix.com",
    "admitone.com",
    "posh.vip",
    "seetickets."
  ]

  def source_url(base_url, collection_id, crumb) do
    today = DateHelpers.today()

    "#{base_url}/api/open/GetItemsByMonth?month=#{today.month}-#{today.year}&collectionId=#{collection_id}&crumb=#{crumb}"
  end

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    ParseHelpers.maybe_decode!(body)
  end

  def next_page_url(current_url, base_url, collection_id, crumb) do
    next_month = DateHelpers.today() |> Date.shift(month: 1)

    next_page_url =
      "#{base_url}/api/open/GetItemsByMonth?month=#{next_month.month}-#{next_month.year}&collectionId=#{collection_id}&crumb=#{crumb}"

    if current_url == next_page_url do
      nil
    else
      next_page_url
    end
  end

  # SquareSpace's GetItemsByMonth response no longer carries the item's `id`,
  # `urlId` or top-level `startDate` / `endDate` - the trimmed item only has
  # `fullUrl` and a `structuredContent` map.  `fullUrl` is unique within a
  # collection, so it stands in as the event identity.
  def event_id(event) do
    event["fullUrl"]
  end

  def ignored_event_id(event) do
    event_id(event)
  end

  def event_title(event) do
    event["title"]
    |> ParseHelpers.fix_encoding()
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event
    |> start_date_ms()
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_date()
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event
    |> start_date_ms()
    |> DateTime.from_unix!(:millisecond)
    |> DateHelpers.to_eastern_datetime()
    |> DateTime.to_time()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  # The SquareSpace item has no ticket field - the vendor link, when there is
  # one, is an anchor inside the `excerpt` HTML.  Most excerpts that carry a
  # link point at the performer's Instagram instead, so a link only counts as a
  # ticket link when it points at a known vendor.
  def ticket_url(event) do
    event["excerpt"]
    |> links()
    |> Enum.find(&ticket_link?/1)
    |> ParseHelpers.sanitize_ticket_url()
  end

  def details_url(event, base_url) do
    base_url <> event["fullUrl"]
  end

  # The start timestamp now lives in `structuredContent`.  Older responses
  # (and any that SquareSpace reverts) carry an identical copy at the top
  # level, so fall back to it rather than assuming one shape.
  defp start_date_ms(event) do
    get_in(event, ["structuredContent", "startDate"]) || event["startDate"]
  end

  defp links(nil), do: []

  defp links(excerpt) do
    ~r/<a[^>]*href="([^"]+)"/
    |> Regex.scan(excerpt)
    |> Enum.map(fn [_match, href] -> ParseHelpers.fix_encoding(href) end)
    |> Enum.filter(&String.starts_with?(&1, "http"))
  end

  defp ticket_link?(url) do
    Enum.any?(@ticket_hosts, &String.contains?(url, &1))
  end
end
