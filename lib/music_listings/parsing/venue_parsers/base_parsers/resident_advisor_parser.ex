defmodule MusicListings.Parsing.VenueParsers.BaseParsers.ResidentAdvisorParser do
  @moduledoc """
  Base parser for venues listed on Resident Advisor (ra.co).

  We call RA's GraphQL API.

  Venue parsers pass their RA club id to `retrieve_events_fun/1` (to scope the
  query) and to `events/2` (to scope the results), and delegate the rest of the
  `VenueParser` callbacks here.
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  require Logger

  @base_url "https://ra.co"
  @graphql_url "#{@base_url}/graphql"

  # Captured from ra.co's own listing request. The type names (FilterInput,
  # FilterSortFieldType, ...) are part of RA's schema and it rejects the query
  # if they drift, so keep them in step with the site if this ever breaks.
  @query """
  query GET_DEFAULT_EVENTS_LISTING($indices: [IndexType!], $filters: [FilterInput], $pageSize: Int, $page: Int, $sortField: FilterSortFieldType, $sortOrder: FilterSortOrderType) {
    listing(indices: $indices, aggregations: [], filters: $filters, pageSize: $pageSize, page: $page, sortField: $sortField, sortOrder: $sortOrder) {
      data {
        ... on Event {
          id
          title
          date
          startTime
          contentUrl
          venue {
            id
            name
          }
        }
      }
      totalResults
    }
  }
  """

  # We fetch a single page. The clubs we track list well under this many
  # upcoming events, so rather than implement pagination we take a page big
  # enough to make it moot and warn (see `events/2`) if a club ever outgrows it.
  @page_size 100

  def build_source_url(club_id), do: "#{@base_url}/clubs/#{club_id}"

  def retrieve_events_fun(club_id) do
    # The url is the club page (see `build_source_url/1`), which we can't fetch
    # from Render - the club id is baked into the query instead, so it's unused.
    fn _url ->
      HttpClient.post(@graphql_url, request_body(club_id), request_headers(club_id))
    end
  end

  def events(body, club_id) do
    listing =
      body
      |> ParseHelpers.maybe_decode!()
      |> get_in(["data", "listing"])

    case listing do
      %{"data" => events} when is_list(events) ->
        maybe_warn_truncated(listing, club_id)
        Enum.filter(events, &(get_in(&1, ["venue", "id"]) == club_id))

      _unexpected_shape ->
        []
    end
  end

  def next_page_url(_body, _current_url), do: nil

  def event_id(event, venue_id_prefix), do: "#{venue_id_prefix}_#{event["id"]}"

  def event_title(event), do: event["title"]

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event["date"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  def additional_dates(_event), do: []

  def event_time(event) do
    case event["startTime"] do
      nil ->
        nil

      start_time ->
        start_time
        |> NaiveDateTime.from_iso8601!()
        |> NaiveDateTime.to_time()
    end
  end

  def price(_event), do: Price.unknown()

  def age_restriction(_event), do: :unknown

  def ticket_url(_event), do: nil

  def details_url(event), do: "#{@base_url}#{event["contentUrl"]}"

  # We only ask for one page, so a club with more upcoming events than @page_size
  # would be silently truncated. Say so rather than quietly dropping events.
  defp maybe_warn_truncated(%{"totalResults" => total}, club_id) when total > @page_size do
    Logger.warning(
      "RA club #{club_id} has #{total} upcoming events but we only fetch #{@page_size} - events are being dropped, add pagination"
    )
  end

  defp maybe_warn_truncated(_listing, _club_id), do: :ok

  defp request_body(club_id) do
    filters = [
      %{"type" => "CLUB", "value" => club_id},
      %{"type" => "DATERANGE", "value" => Jason.encode!(%{"gte" => gte()})}
    ]

    %{
      "operationName" => "GET_DEFAULT_EVENTS_LISTING",
      "query" => @query,
      "variables" => %{
        "indices" => ["EVENT"],
        "filters" => filters,
        "pageSize" => @page_size,
        "page" => 1,
        "sortField" => "EVENTDATE",
        "sortOrder" => "ASCENDING"
      }
    }
  end

  defp gte do
    DateHelpers.now()
    |> DateTime.to_iso8601()
  end

  # This is the exact header set verified to return 200 from Render. The
  # user-agent is not known to be load-bearing (DataDome blocks the club pages
  # on IP, not headers) - but it is what we tested, so it is what we ship.
  defp request_headers(club_id) do
    [
      {"content-type", "application/json"},
      {"accept", "*/*"},
      {"ra-content-language", "en"},
      {"origin", @base_url},
      {"referer", "#{build_source_url(club_id)}/events"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"}
    ]
  end
end
