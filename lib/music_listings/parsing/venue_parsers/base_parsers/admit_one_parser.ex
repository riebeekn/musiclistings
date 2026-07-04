defmodule MusicListings.Parsing.VenueParsers.BaseParsers.AdmitOneParser do
  @moduledoc """
  Base parser for sites using admit one json data
  """
  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @community_graphql_url "https://graphql.admitone.com/"
  @community_query """
  query VenueEventsList($skip: Int!, $take: Int!, $eventGroupTag: String) {
    events(skip: $skip, take: $take, eventGroupTag: $eventGroupTag) {
      items {
        id
        title
        timezone
        startDate
        status
        address { formattedAddress city businessName }
        presentedBy
        presentedByName
        eventImage
      }
      skip
      take
      total
    }
  }
  """

  @doc """
  Returns a closure that fetches events for the venue.

  The REST `gateway.admitone.com` feed (ticketed "PRO" events) is always
  fetched.  When `event_group_tag` is a non-empty string the closure also
  fetches the `graphql.admitone.com` "community" feed for that tag and merges
  the normalized community events in — mirroring the venue sites' own widget.
  """
  def retrieve_events_fun(event_group_tag \\ nil) do
    fn url ->
      case HttpClient.get(url) do
        {:ok, %HttpClient.Response{status: 200, body: body}} ->
          rest_events = ParseHelpers.maybe_decode!(body)["events"] || []
          merged = rest_events ++ community_events(event_group_tag)
          {:ok, %HttpClient.Response{status: 200, body: %{"events" => merged}}}

        other ->
          other
      end
    end
  end

  def events(body) do
    body = ParseHelpers.maybe_decode!(body)

    body["events"]
  end

  defp community_events(event_group_tag)
       when is_binary(event_group_tag) and event_group_tag != "" do
    headers = [{"content-type", "application/json"}]

    body = %{
      query: @community_query,
      variables: %{take: 9999, skip: 0, eventGroupTag: event_group_tag}
    }

    case HttpClient.post(@community_graphql_url, body, headers) do
      {:ok, %HttpClient.Response{status: 200, body: response_body}} ->
        response_body
        |> ParseHelpers.maybe_decode!()
        |> get_in(["data", "events", "items"])
        |> Kernel.||([])
        |> Enum.map(&normalize_community_event/1)

      _other ->
        []
    end
  end

  defp community_events(_event_group_tag), do: []

  @doc """
  Normalizes a GraphQL "community" event into the same map shape the REST feed
  returns, so all the field-extraction callbacks below work unchanged.
  """
  def normalize_community_event(item) do
    {:ok, utc_datetime, _offset} = DateTime.from_iso8601(item["startDate"])
    eastern = DateHelpers.to_eastern_datetime(utc_datetime)

    %{
      "title" => item["title"],
      "event_date" => Calendar.strftime(eastern, "%B %-d %Y"),
      "doors" => Calendar.strftime(eastern, "%-I:%M %p"),
      "age_limit" => nil,
      "url" => "https://community.admitone.com/events/#{item["id"]}"
    }
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_id(event, venue_name) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime(venue_name, date, time)
  end

  def event_title(event) do
    event["title"]
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    [month_string, day_string, year_string] = event["event_date"] |> String.split()

    {:ok, date} =
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)

    date
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    case event["doors"]
         |> ParseHelpers.build_time_from_time_string() do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(event) do
    event["age_limit"]
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  def ticket_url(event) do
    event["url"]
  end

  def details_url(_event) do
    nil
  end
end
