defmodule MusicListings.Parsing.VenueParsers.TimothysPubParser do
  @moduledoc """
  Parser for extracting events from https://www.timothyspub.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.TockifyParser

  @venue_name "timothys_pub"
  @calendar_name "robinbrem"

  @impl true
  def source_url do
    TockifyParser.build_source_url(@calendar_name)
  end

  @impl true
  defdelegate retrieve_events_fun, to: TockifyParser

  @impl true
  def example_data_file_location, do: "test/data/timothys_pub/index.json"

  @impl true
  def events(body) do
    TockifyParser.events(body)
    |> Enum.filter(&has_live_music_tag?/1)
  end

  defp has_live_music_tag?(event) do
    tags = get_in(event, ["content", "tagset", "tags", "default"]) || []
    "LIVE-@-TIMOTHY'S-PUB" in tags
  end

  @impl true
  defdelegate next_page_url(body, current_url), to: TockifyParser

  @impl true
  def event_id(event) do
    TockifyParser.event_id_from_date(@venue_name, event)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: TockifyParser

  @impl true
  defdelegate performers(event), to: TockifyParser

  @impl true
  defdelegate event_date(event), to: TockifyParser

  @impl true
  defdelegate additional_dates(event), to: TockifyParser

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  defdelegate price(event), to: TockifyParser

  @impl true
  defdelegate age_restriction(event), to: TockifyParser

  @impl true
  defdelegate ticket_url(event), to: TockifyParser

  @impl true
  defdelegate details_url(event), to: TockifyParser
end
