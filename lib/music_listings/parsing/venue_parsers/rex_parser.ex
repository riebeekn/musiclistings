defmodule MusicListings.Parsing.VenueParsers.RexParser do
  @moduledoc """
  Parser for extracing events from https://www.therex.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceJsonParser

  @base_url "https://www.therex.ca"
  @collection_id "62099f5a37eb917826df65cc"
  @crumb "BZxZJlGW0oALYzcxZDM5MjgzOGE1NmQ0ZTcyOWY3NjdhZWFmMDVi"

  @impl true
  def source_url do
    SquareSpaceJsonParser.source_url(@base_url, @collection_id, @crumb)
  end

  @impl true
  defdelegate retrieve_events_fun, to: SquareSpaceJsonParser

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
