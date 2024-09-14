defmodule MusicListings.Parsing.VenueParsers.PoetryJazzCafeParser do
  @moduledoc """
  Parser for extracing events from https://www.poetryjazzcafe.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceParser

  @base_url "https://www.poetryjazzcafe.com"

  @impl true
  def source_url, do: "#{@base_url}/livemusic"

  @impl true
  defdelegate retrieve_events_fun, to: SquareSpaceParser

  @impl true
  def example_data_file_location, do: "test/data/poetry_jazz_cafe/index.html"

  @impl true
  defdelegate events(body), to: SquareSpaceParser

  @impl true
  defdelegate next_page_url(body, current_url), to: SquareSpaceParser

  @impl true
  defdelegate event_id(event), to: SquareSpaceParser

  @impl true
  defdelegate ignored_event_id(event), to: SquareSpaceParser

  @impl true
  defdelegate event_title(event), to: SquareSpaceParser

  @impl true
  defdelegate performers(event), to: SquareSpaceParser

  @impl true
  defdelegate event_date(event), to: SquareSpaceParser

  @impl true
  defdelegate additional_dates(event), to: SquareSpaceParser

  @impl true
  defdelegate event_time(event), to: SquareSpaceParser

  @impl true
  defdelegate price(event), to: SquareSpaceParser

  @impl true
  defdelegate age_restriction(event), to: SquareSpaceParser

  @impl true
  defdelegate ticket_url(event), to: SquareSpaceParser

  @impl true
  def details_url(event) do
    SquareSpaceParser.details_url(event, @base_url)
  end
end
