defmodule MusicListings.Parsing.VenueParsers.HirutParser do
  @moduledoc """
  Parser for extracting events from https://www.hirutjazz.ca/copy-of-live-shows

  The Wix page embeds an Inffuse "Events Calendar" widget, which reads the venue's events
  from a public JSON endpoint keyed on the calendar's project id (no Wix instance token is
  needed), i.e.

      %{"result" => true,
        "value" => [%{"id" => "event_8dw82LLE8MbzjgN9Q0GFQ",
                      "title" => "Mark Eisenman Quartet",
                      "description" => "pianist Mark Eisenman Quartet w/...\\n$20 Cash Cover Charge",
                      "startDate" => "2026-11-19", "startHour" => 20, "startMinutes" => 0,
                      "allday" => false, ...}]}

  The endpoint returns every event back to 2023; past ones are dropped by the crawler.
  `startDate`/`startHour`/`startMinutes` are Toronto wall clock time.  Events are often
  copied from an earlier one and keep its id, so the id is built from the date instead
  (the venue has at most one show a night).

  Comedy nights (Hirut Hoot), closed days and restaurant-only nights are skipped.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @source_url "https://www.hirutjazz.ca/copy-of-live-shows"
  @events_url "https://inffuse.eventscalendar.co/api/v0.1/projects/proj_qxJgKMsbxAQ8KiG3Zrgbl/data/public/events?app=calendar"

  @skipped_title ~r/\bclosed\b|\bhoot\b|comedy|^restaurant\b|chef'?s night/i
  @price ~r/\$\s*\d+(?:\.\d{2})?/

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn _url -> HttpClient.get(@events_url, [{"accept", "application/json"}]) end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("value", [])
    |> Enum.reject(&(event_title(&1) =~ @skipped_title))
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event), do: ParseHelpers.build_id_from_venue_and_date("hirut", event_date(event))

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event["title"]
    |> String.trim()
    |> String.trim("\"")
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: Date.from_iso8601!(event["startDate"])

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(%{"allday" => true}), do: nil

  def event_time(%{"startHour" => hour, "startMinutes" => minutes})
      when is_integer(hour) and is_integer(minutes),
      do: Time.new!(hour, minutes, 0)

  def event_time(_event), do: nil

  # The cover charge is in the description, e.g. "$20 Cash Cover Charge"
  @impl true
  def price(event) do
    case Regex.run(@price, event["description"] || "") do
      [price] -> Price.new(price)
      nil -> Price.unknown()
    end
  end

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url
end
