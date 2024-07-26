defmodule MusicListings.Parsing.VenueParsers.TDMusicHallParser do
  @moduledoc """
  Parser for extracing events from https://masseyhall.mhrth.com/
  """
  @behaviour MusicListings.Parsing.Parser

  alias MusicListings.Parsing.VenueParsers.MhRthTdmhParser

  @td_music_hall_facility_no "301"

  @impl true
  defdelegate source_url, to: MhRthTdmhParser

  @impl true
  def venue_name, do: "TD Music Hall"

  @impl true
  def example_data_file_location, do: "test/data/td_music_hall/index.json"

  @impl true
  def event_selector(body) do
    MhRthTdmhParser.event_selector(body, @td_music_hall_facility_no)
  end

  @impl true
  defdelegate next_page_url(body), to: MhRthTdmhParser

  @impl true
  defdelegate event_id(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_title(event), to: MhRthTdmhParser

  @impl true
  defdelegate performers(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_date(event), to: MhRthTdmhParser

  @impl true
  defdelegate event_time(event), to: MhRthTdmhParser

  @impl true
  defdelegate price(event), to: MhRthTdmhParser

  @impl true
  defdelegate age_restriction(event), to: MhRthTdmhParser

  @impl true
  defdelegate ticket_url(event), to: MhRthTdmhParser
end
