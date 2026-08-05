defmodule MusicListings.Parsing.VenueParsers.MazzoleniConcertHallParser do
  @moduledoc """
  Parser for extracing events from https://www.rcmusic.com/concerts

  The site files this room under two `eventvenue` facet values, "Mazzoleni
  Concert Hall" and "Mazzoleni Hall"; both are the hall in Ihnatowycz Hall, so
  we crawl both.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.Parsing.VenueParsers.BaseParsers.RcmParser

  @impl true
  def source_url, do: List.first(source_urls())

  @impl true
  defdelegate retrieve_events_fun, to: RcmParser

  @impl true
  defdelegate events(body), to: RcmParser

  @impl true
  def next_page_url(body, current_url) do
    RcmParser.next_page_url(body, current_url, source_urls())
  end

  @impl true
  defdelegate event_id(event), to: RcmParser

  @impl true
  defdelegate ignored_event_id(event), to: RcmParser

  @impl true
  defdelegate event_title(event), to: RcmParser

  @impl true
  defdelegate performers(event), to: RcmParser

  @impl true
  defdelegate event_date(event), to: RcmParser

  @impl true
  defdelegate additional_dates(event), to: RcmParser

  @impl true
  defdelegate event_time(event), to: RcmParser

  @impl true
  defdelegate price(event), to: RcmParser

  @impl true
  defdelegate age_restriction(event), to: RcmParser

  @impl true
  defdelegate ticket_url(event), to: RcmParser

  @impl true
  defdelegate details_url(event), to: RcmParser

  defp source_urls do
    [
      RcmParser.build_source_url("Royal Conservatory Concerts", "Mazzoleni Concert Hall"),
      RcmParser.build_source_url("Royal Conservatory Concerts", "Mazzoleni Hall"),
      RcmParser.build_source_url("Other Public Events", "Mazzoleni Hall")
    ]
  end
end
