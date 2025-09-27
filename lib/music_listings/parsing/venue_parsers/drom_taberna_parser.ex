defmodule MusicListings.Parsing.VenueParsers.DromTabernaParser do
  @moduledoc """
  Parser for extracing events from https://www.dromtaberna.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.BaseParsers.SquareSpaceJsonParser

  @base_url "https://www.dromtaberna.com"
  @collection_id "62c7b220c14f6e5949312039"
  @crumb "BQ4mS5WCnRzZOTgxYWRjMGUxZTk0Y2MzNjhkYTQ0NGU0ZDA2MGUy"

  @impl true
  def source_url do
    SquareSpaceJsonParser.source_url(@base_url, @collection_id, @crumb)
  end

  @impl true
  defdelegate retrieve_events_fun, to: SquareSpaceJsonParser

  @impl true
  def example_data_file_location, do: "test/data/drom_taberna/index.json"

  @impl true
  def events(body) do
    body
    |> SquareSpaceJsonParser.events()
    |> Enum.reject(fn content -> content["systemDataId"] == "PLACEHOLDER" end)
  end

  @impl true
  def next_page_url(_body, current_url) do
    SquareSpaceJsonParser.next_page_url(current_url, @base_url, @collection_id, @crumb)
  end

  @impl true
  defdelegate event_id(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate ignored_event_id(event), to: SquareSpaceJsonParser

  @impl true
  def event_title(event) do
    full_title =
      event["excerpt"]
      |> Selectors.all_matches(css("p"))
      |> Selectors.text()
      |> Enum.map_join(", ", & &1)

    # strip out times from the title
    time_regex = ~r/\b\d{1,2}\.\d{2}(?:\s*to\s*\d{1,2}\.\d{2})?\s*-\s*/

    full_title
    |> String.replace(time_regex, "")
  end

  @impl true
  def performers(_event) do
    Performers.new([])
  end

  @impl true
  defdelegate event_date(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate additional_dates(event), to: SquareSpaceJsonParser

  @impl true
  def event_time(_event) do
    nil
  end

  @impl true
  defdelegate price(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate age_restriction(event), to: SquareSpaceJsonParser

  @impl true
  defdelegate ticket_url(event), to: SquareSpaceJsonParser

  @impl true
  def details_url(event) do
    "https://www.dromtaberna.com#{event["fullUrl"]}"
  end
end
