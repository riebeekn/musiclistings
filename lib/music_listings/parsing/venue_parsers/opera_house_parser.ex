defmodule MusicListings.Parsing.VenueParsers.OperaHouseParser do
  @moduledoc """
  Parser for extracing events from https://theoperahousetoronto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.LiveNationParser

  @impl true
  defdelegate source_url, to: LiveNationParser

  @live_nation_venue_id "KovZpZAFlvvA"
  @impl true
  def retrieve_events_fun do
    LiveNationParser.retrieve_events_fun(@live_nation_venue_id)
  end

  @impl true
  def example_data_file_location, do: "test/data/opera_house/index.json"

  @impl true
  defdelegate events(body), to: LiveNationParser

  @impl true
  defdelegate next_page_url(body, current_url), to: LiveNationParser

  @impl true
  defdelegate event_id(event), to: LiveNationParser

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: LiveNationParser

  @impl true
  defdelegate performers(event), to: LiveNationParser

  @impl true
  defdelegate event_date(event), to: LiveNationParser

  @impl true
  defdelegate additional_dates(event), to: LiveNationParser

  @impl true
  defdelegate event_time(event), to: LiveNationParser

  @impl true
  defdelegate price(event), to: LiveNationParser

  @impl true
  defdelegate age_restriction(event), to: LiveNationParser

  @impl true
  defdelegate ticket_url(event), to: LiveNationParser

  @impl true
  defdelegate details_url(event), to: LiveNationParser
end
