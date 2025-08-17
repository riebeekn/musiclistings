defmodule MusicListings.Parsing.VenueParsers.TDMusicHallParser do
  @moduledoc """
  Parser for extracing events from https://tdmusichall.mhrth.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser

  @base_url "https://tdmusichall.mhrth.com"
  @impl true
  def source_url, do: "#{@base_url}/tickets/?page=1"

  @impl true
  defdelegate retrieve_events_fun, to: MhRthTdmhParser

  @impl true
  def example_data_file_location, do: "test/data/td_music_hall/index.html"

  @impl true
  defdelegate events(body), to: MhRthTdmhParser

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
  def details_url(event) do
    details_path = MhRthTdmhParser.details_url(event)
    "#{@base_url}#{details_path}"
  end
end
