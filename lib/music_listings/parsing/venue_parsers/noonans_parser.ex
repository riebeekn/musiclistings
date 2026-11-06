defmodule MusicListings.Parsing.VenueParsers.NoonansParser do
  @moduledoc """
  Parser for extracting events from https://noonanspub.ca/

  The site's home page loads its calendar from `events_refresh.php`, an HTML
  fragment holding a single table.  A date gets a row of its own and the events
  on that date follow in the rows after it, so each event is built up with the
  date row it falls under.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @timed_event_regex ~r/^(\d{1,2}:\d{2}\s*[ap]m)\s*-\s*(.+)$/i

  @impl true
  def source_url, do: "https://noonanspub.ca/events_refresh.php"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("table.events-table tr"))
    |> Enum.flat_map_reduce(nil, &parse_row/2)
    |> elem(0)
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  # The feed has no ids.  Venue and time won't do for the id as two events can
  # share a start time, and not all events have a time, so use the title.
  @impl true
  def event_id(event) do
    event
    |> event_title()
    |> ParseHelpers.build_id_from_title_and_date(event_date(event))
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event["title"]

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week, month_string, day_string] = String.split(event["date"])

    {:ok, date} = ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
    date
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: ParseHelpers.time_from_time_string(event["time"])

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: "https://noonanspub.ca/"

  defp parse_row(row, current_date) do
    text = row |> Selectors.text(css("td")) |> String.trim()

    if Selectors.attr(row, "class") == "event-date-row" do
      {[], text}
    else
      {[build_event(text, current_date)], current_date}
    end
  end

  defp build_event(text, date) do
    case Regex.run(@timed_event_regex, text) do
      [_text, time, title] -> %{"date" => date, "time" => time, "title" => clean_title(title)}
      nil -> %{"date" => date, "time" => nil, "title" => clean_title(text)}
    end
  end

  # The same act is listed with straight and curly apostrophes on different dates
  defp clean_title(title) do
    title
    |> String.replace("’", "'")
    |> String.trim()
  end
end
