defmodule MusicListings.Parsing.VenueParsers.LeesPalaceParser do
  @moduledoc """
  Parser for extracing events from https://www.leespalace.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.VenueParsers.BaseParsers.HorseshoeLeesParser

  @base_url "https://www.leespalace.com"

  @impl true
  def source_url, do: HorseshoeLeesParser.source_url(@base_url)

  @impl true
  defdelegate retrieve_events_fun, to: HorseshoeLeesParser

  @impl true
  defdelegate events(body), to: HorseshoeLeesParser

  @impl true
  defdelegate next_page_url(body, current_url), to: HorseshoeLeesParser

  @impl true
  def event_id(event) do
    title = event |> event_title() |> String.split() |> List.first()
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  defdelegate event_title(event), to: HorseshoeLeesParser

  @impl true
  defdelegate performers(event), to: HorseshoeLeesParser

  @impl true
  defdelegate event_date(event), to: HorseshoeLeesParser

  @impl true
  defdelegate additional_dates(event), to: HorseshoeLeesParser

  @impl true
  defdelegate event_time(event), to: HorseshoeLeesParser

  @impl true
  defdelegate price(event), to: HorseshoeLeesParser

  @impl true
  defdelegate age_restriction(event), to: HorseshoeLeesParser

  @impl true
  defdelegate ticket_url(event), to: HorseshoeLeesParser

  @impl true
  def details_url(event) do
    HorseshoeLeesParser.details_url(event, @base_url)
  end
end
