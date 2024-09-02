defmodule MusicListings.Parsing.VenueParsers.AnnabelsParser do
  @moduledoc """
  Parser for extracing events from https://www.annabelsto.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.AdmitOneParser

  @impl true
  def source_url,
    do:
      "https://gateway.admitone.com/embed/live-events?venueId=644bf7abee86fe5385227413&order=asc"

  @impl true
  def example_data_file_location, do: "test/data/annabels/index.json"

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