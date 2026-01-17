defmodule MusicListings.Parsing.VenueParsers.JunctionUndergroundParser do
  @moduledoc """
  Parser for extracting events from https://junctionunderground.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.Selectors
  alias MusicListings.Parsing.VenueParsers.BaseParsers.WordpressParser

  @impl true
  def source_url, do: "https://junctionunderground.ca/events/"

  @impl true
  defdelegate retrieve_events_fun, to: WordpressParser

  @impl true

  def events(body) do
    body
    |> Selectors.all_matches(css("script[type=\"application/ld+json\"]"))
    |> Enum.map(&Selectors.data/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.flat_map(&parse_json_ld/1)
    |> Enum.filter(&event?/1)
  end

  defp parse_json_ld(json_string) do
    case Jason.decode(json_string) do
      {:ok, list} when is_list(list) -> list
      {:ok, map} when is_map(map) -> [map]
      _fallthru -> []
    end
  rescue
    _fallthru -> []
  end

  defp event?(%{"@type" => "Event"}), do: true
  defp event?(_type), do: false

  @impl true
  defdelegate next_page_url(body, current_url), to: WordpressParser

  @impl true
  def event_id(event) do
    WordpressParser.event_id(event, "junction_underground")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: WordpressParser

  @impl true
  defdelegate performers(event), to: WordpressParser

  @impl true
  defdelegate event_date(event), to: WordpressParser

  @impl true
  defdelegate additional_dates(event), to: WordpressParser

  @impl true
  defdelegate event_time(event), to: WordpressParser

  @impl true
  defdelegate price(event), to: WordpressParser

  @impl true
  defdelegate age_restriction(event), to: WordpressParser

  @impl true
  defdelegate ticket_url(event), to: WordpressParser

  @impl true
  defdelegate details_url(event), to: WordpressParser
end
