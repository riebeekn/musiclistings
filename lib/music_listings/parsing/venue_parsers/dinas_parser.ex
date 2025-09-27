defmodule MusicListings.Parsing.VenueParsers.DinasParser do
  @moduledoc """
  Parser for extracting events from https://www.dinastavern.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceJsonParser

  @base_url "https://www.dinastavern.com"
  @collection_id "68ae25e366b1226c46621c27"
  @crumb "BSnq4OaZLAN4MjM2MDY2ZmIyYmRkZWJmYjA0MWM3YTk2ZTRmNmE0"

  @impl true
  def source_url do
    SquareSpaceJsonParser.source_url(@base_url, @collection_id, @crumb)
  end

  @impl true
  defdelegate retrieve_events_fun, to: SquareSpaceJsonParser

  @impl true
  def example_data_file_location, do: "test/data/dinas/index.json"

  @impl true
  defdelegate events(body), to: SquareSpaceJsonParser

  @impl true
  def next_page_url(_body, current_url) do
    SquareSpaceJsonParser.next_page_url(current_url, @base_url, @collection_id, @crumb)
  end

  @impl true
  defdelegate event_id(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate ignored_event_id(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate event_title(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate performers(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate event_date(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate additional_dates(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate event_time(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate price(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate age_restriction(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate ticket_url(event), to: SquareSpaceJsonParser

  @impl true
  def details_url(event) do
    SquareSpaceJsonParser.details_url(event, @base_url)
  end
end
