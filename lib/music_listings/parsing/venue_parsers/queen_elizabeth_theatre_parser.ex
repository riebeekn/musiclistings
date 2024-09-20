defmodule MusicListings.Parsing.VenueParsers.QueenElizabthTheatreParser do
  @moduledoc """
  Parser for extracing events from https://www.queenelizabeththeatre.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.AdmitOneParser

  @impl true
  def source_url,
    do:
      "https://gateway.admitone.com/embed/live-events?venueId=60ad698c2a3c42001744a78f,5f2c38d9b49c22464830180a,5fff3fc4252a3e0017753b8c,60ad698c2a3c42001744a78d,623a293401b1e63c3d61094c&order=asc"

  @impl true
  defdelegate retrieve_events_fun, to: AdmitOneParser

  @impl true
  def example_data_file_location, do: "test/data/queen_elizabeth_theatre/index.json"

  @impl true
  defdelegate events(body), to: AdmitOneParser

  @impl true
  defdelegate next_page_url(body, current_url), to: AdmitOneParser

  @impl true
  defdelegate event_id(event), to: AdmitOneParser

  @impl true
  defdelegate ignored_event_id(event), to: AdmitOneParser

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
