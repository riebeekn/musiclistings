defmodule MusicListings.Parsing.VenueParsers.AdelaideHallParser do
  @moduledoc """
  Parser for extracing events from https://www.adelaidehallto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.AdmitOneParser

  @impl true
  def source_url,
    do:
      "https://gateway.admitone.com/embed/live-events?venueId=5f2c38d9b49c224648301825,6182ec572490d0ef56a4adbe,6201607c4ece4990eeeb6a3c&order=asc"

  @impl true
  defdelegate retrieve_events_fun, to: AdmitOneParser

  @impl true
  def example_data_file_location, do: "test/data/adelaide_hall/index.json"

  @impl true
  defdelegate events(body), to: AdmitOneParser

  @impl true
  defdelegate next_page_url(body, current_url), to: AdmitOneParser

  @impl true
  def event_id(event) do
    AdmitOneParser.event_id(event, "adelaide_hall")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: AdmitOneParser

  @impl true
  defdelegate performers(event), to: AdmitOneParser

  @impl true
  defdelegate event_date(event), to: AdmitOneParser

  @impl true
  defdelegate additional_dates(event), to: AdmitOneParser

  @impl true
  defdelegate event_time(event), to: AdmitOneParser

  @impl true
  defdelegate price(event), to: AdmitOneParser

  @impl true
  defdelegate age_restriction(event), to: AdmitOneParser

  @impl true
  defdelegate ticket_url(event), to: AdmitOneParser

  @impl true
  defdelegate details_url(event), to: AdmitOneParser
end
