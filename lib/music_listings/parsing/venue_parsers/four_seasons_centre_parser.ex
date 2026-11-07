defmodule MusicListings.Parsing.VenueParsers.FourSeasonsCentreParser do
  @moduledoc """
  Parser for extracting events at the Four Seasons Centre for the Performing Arts
  from the Canadian Opera Company's calendar, https://www.coc.ca/tickets/calendar

  The calendar is rendered in the browser from a JSON feed of the COC's productions,
  each with its venue and performances, i.e.

      [%{"ID" => 574, "Title" => "The Turn of the Screw", "Link" => "/tickets/...",
         "Venue" => %{"Title" => "Four Seasons Centre for the Performing Arts", ...},
         "Performances" => [%{"PerformanceNumber" => 2539,
                              "PerformanceDate" => "2027-01-23T19:30:00-05:00", ...}]}]

  `events/1` returns a map per performance, as each has its own time and ticket link,
  of the productions at the Four Seasons Centre, including the Free Concert Series in
  its Richard Bradshaw Amphitheatre.  As the calendar does, it skips productions
  flagged `IsDuplicate` and rehearsal performances.

  A free concert's `Suffix` is its performers (an opera's is its composer), so they're
  taken from it, and its price is free.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @venues ["Four Seasons Centre for the Performing Arts", "Richard Bradshaw Amphitheatre"]
  @site_url "https://www.coc.ca"
  @tickets_url "https://my.coc.ca"

  # The calendar's production types for dress and working rehearsals, and the free concerts
  @rehearsal_type_ids [4, 5]
  @free_concert_type_id -999

  @impl true
  def source_url, do: "https://d1ndd0kfyiplr2.cloudfront.net/Prod/events/10/40/Live"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url, [{"accept", "application/json"}]) end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Enum.filter(&(get_in(&1, ["Venue", "Title"]) in @venues and &1["IsDuplicate"] == 0))
    |> Enum.flat_map(&performances/1)
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    "four_seasons_centre_#{event["ID"]}_#{event["PerformanceNumber"]}"
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: String.trim(event["Title"])

  @impl true
  def performers(event) do
    suffix = event["Suffix"] && String.trim(event["Suffix"])

    if free_concert?(event) and suffix not in [nil, ""] do
      Performers.new([suffix])
    else
      Performers.new([event_title(event)])
    end
  end

  @impl true
  def event_date(event), do: event |> performance_datetime() |> NaiveDateTime.to_date()

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event |> performance_datetime() |> NaiveDateTime.to_time()

  @impl true
  def price(event) do
    if free_concert?(event), do: Price.new("free"), else: Price.unknown()
  end

  @impl true
  def age_restriction(_event), do: :unknown

  # As the calendar links them: a production's own booking link, else the
  # performance's page on the ticketing site, unless it's sold out
  @impl true
  def ticket_url(%{"CustomBookingLink" => link}) when is_binary(link) and link != "", do: link
  def ticket_url(%{"Availability" => 0}), do: nil

  def ticket_url(%{"ProductionSeasonNumber" => season, "PerformanceNumber" => performance})
      when is_integer(season) and is_integer(performance),
      do: "#{@tickets_url}/#{season}/#{performance}"

  def ticket_url(_event), do: nil

  @impl true
  def details_url(%{"Link" => "/" <> _path = link}), do: @site_url <> link
  def details_url(%{"Link" => link}), do: link

  # A map per performance, carrying its production's fields
  defp performances(production) do
    {performances, production} = Map.pop(production, "Performances", [])

    performances
    |> Enum.reject(&rehearsal?/1)
    |> Enum.map(&Map.merge(production, &1))
  end

  # The offset is Toronto's, so the wall clock time is kept as is
  defp performance_datetime(event) do
    NaiveDateTime.from_iso8601!(event["PerformanceDate"])
  end

  defp free_concert?(event), do: production_type?(event, [@free_concert_type_id])

  defp rehearsal?(performance), do: production_type?(performance, @rehearsal_type_ids)

  defp production_type?(performance, type_ids) do
    performance
    |> Map.get("ProductionTypes", [])
    |> Enum.any?(&(&1["ID"] in type_ids))
  end
end
