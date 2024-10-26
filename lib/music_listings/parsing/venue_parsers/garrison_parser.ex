defmodule MusicListings.Parsing.VenueParsers.GarrisonParser do
  @moduledoc """
  Parser for extracing events from http://www.garrisontoronto.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.BgGarrisonParser

  @impl true
  def source_url, do: "http://www.garrisontoronto.com/listings.html"

  @impl true
  defdelegate retrieve_events_fun, to: BgGarrisonParser

  @impl true
  def example_data_file_location, do: "test/data/garrison/index.html"

  @impl true
  defdelegate events(body), to: BgGarrisonParser

  @impl true
  defdelegate next_page_url(body, current_url), to: BgGarrisonParser

  @impl true
  def event_id(event) do
    BgGarrisonParser.event_id(event, "garrison")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: BgGarrisonParser

  @impl true
  defdelegate performers(event), to: BgGarrisonParser

  @impl true
  defdelegate event_date(event), to: BgGarrisonParser

  @impl true
  defdelegate additional_dates(event), to: BgGarrisonParser

  @impl true
  defdelegate event_time(event), to: BgGarrisonParser

  @impl true
  defdelegate price(event), to: BgGarrisonParser

  @impl true
  defdelegate age_restriction(event), to: BgGarrisonParser

  @impl true
  defdelegate ticket_url(event), to: BgGarrisonParser

  @impl true
  defdelegate details_url(event), to: BgGarrisonParser
end
