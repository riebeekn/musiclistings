defmodule MusicListings.Parsing.VenueParsers.ScotiabankParser do
  @moduledoc """
  Parser for extracing events from https://www.scotiabankarena.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.CarbonhouseParser

  @impl true
  def source_url,
    do:
      "https://www.scotiabankarena.com/events/events_ajax/0?category=1&venue=0&team=0&exclude=&per_page=63&came_from_page=event-list-page"

  @impl true
  def example_data_file_location, do: "test/data/scotiabank/index.html"

  @impl true
  defdelegate events(body), to: CarbonhouseParser

  @impl true
  defdelegate next_page_url(body, current_url), to: CarbonhouseParser

  @impl true
  defdelegate event_id(event), to: CarbonhouseParser

  @impl true
  defdelegate ignored_event_id(event), to: CarbonhouseParser

  @impl true
  defdelegate event_title(event), to: CarbonhouseParser

  @impl true
  defdelegate performers(event), to: CarbonhouseParser

  @impl true
  defdelegate event_date(event), to: CarbonhouseParser

  @impl true
  defdelegate additional_dates(event), to: CarbonhouseParser

  @impl true
  defdelegate event_time(event), to: CarbonhouseParser

  @impl true
  defdelegate price(event), to: CarbonhouseParser

  @impl true
  defdelegate age_restriction(event), to: CarbonhouseParser

  @impl true
  defdelegate ticket_url(event), to: CarbonhouseParser

  @impl true
  defdelegate details_url(event), to: CarbonhouseParser
end
