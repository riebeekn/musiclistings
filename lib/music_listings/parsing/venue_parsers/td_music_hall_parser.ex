defmodule MusicListings.Parsing.VenueParsers.TDMusicHallParser do
  @moduledoc """
  Parser for extracing events from https://masseyhall.mhrth.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.MhRthTdmhParser

  @td_music_hall_facility_no 301

  @impl true
  defdelegate source_url, to: MhRthTdmhParser

  @impl true
  def example_data_file_location, do: "test/data/td_music_hall/index.json"

  @impl true
  def events(body) do
    MhRthTdmhParser.event(body, @td_music_hall_facility_no)
  end

  @impl true
  defdelegate next_page_url(body, current_url), to: MhRthTdmhParser

  @impl true
  defdelegate event_id(event), to: MhRthTdmhParser

  @impl true
  defdelegate ignored_event_id(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_title(event), to: MhRthTdmhParser

  @impl true
  defdelegate performers(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_date(event), to: MhRthTdmhParser

  @impl true
  defdelegate additional_dates(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_time(event), to: MhRthTdmhParser

  @impl true
  defdelegate price(event), to: MhRthTdmhParser

  @impl true
  defdelegate age_restriction(event), to: MhRthTdmhParser

  @impl true
  defdelegate ticket_url(event), to: MhRthTdmhParser

  @impl true
  defdelegate details_url(event), to: MhRthTdmhParser
end
