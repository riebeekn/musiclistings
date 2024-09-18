defmodule MusicListings.Parsing.VenueParsers.MeridianHallParser do
  @moduledoc """
  Parser for extracing events from https://www.tolive.com/Meridian-Hall-Events
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @impl true
  def source_url,
    do:
      "https://cdn.contentful.com/spaces/nmxu5kj1b6ch/environments/master/entries?metadata.tags.sys.id%5Ball%5D=genreConcerts%2CmeridianHall&locale=en-US&include=1&limit=1000&order=-sys.createdAt"

  @impl true
  def retrieve_events_fun do
    fn url ->
      headers = [
        {"accept", "application/json, text/plain, */*"},
        {"authorization", "Bearer 6-Q_VzBlEPeEgD0gyS_c9s7a6N_0597J7RukeSb2hfA"}
      ]

      Req.get(url, headers: headers)
    end
  end

  @impl true
  def example_data_file_location, do: "test/data/meridian_hall/index.json"

  @impl true
  def events(body) do
    body = ParseHelpers.maybe_decode!(body)
    body["items"]
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["fields"]["billingName"]
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    date_string = ParseHelpers.add_seconds_to_datetime_string(event["fields"]["dateTime"])
    {:ok, datetime, _offset} = DateTime.from_iso8601(date_string)
    DateHelpers.to_eastern_date(datetime)
  end

  @impl true
  def additional_dates(event) do
    end_date_string = event["fields"]["eventEndDateTime"]

    if end_date_string do
      start_date_string = ParseHelpers.add_seconds_to_datetime_string(event["fields"]["dateTime"])
      {:ok, start_date, _offset} = DateTime.from_iso8601(start_date_string)
      est_start_date = DateHelpers.to_eastern_date(start_date)

      end_date_string = ParseHelpers.add_seconds_to_datetime_string(end_date_string)
      {:ok, end_date, _offset} = DateTime.from_iso8601(end_date_string)
      est_end_date = DateHelpers.to_eastern_date(end_date)

      [_opening_date | remaining_dates] =
        Date.range(est_start_date, est_end_date) |> Enum.to_list()

      remaining_dates
    else
      []
    end
  end

  @impl true
  def event_time(event) do
    date_string = ParseHelpers.add_seconds_to_datetime_string(event["fields"]["dateTime"])
    {:ok, datetime, _offset} = DateTime.from_iso8601(date_string)
    DateHelpers.to_eastern_time(datetime)
  end

  @impl true
  def price(_event) do
    Price.unknown()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(event) do
    event["fields"]["ctaLabelUrl1"]
    |> case do
      nil -> nil
      ticket_url -> String.replace(ticket_url, "External:", "")
    end
  end

  @impl true
  def details_url(event) do
    slug = event["fields"]["id"] |> String.replace(" ", "-")
    "https://tolive.com/Event-Details-Page/reference/#{slug}"
  end
end
