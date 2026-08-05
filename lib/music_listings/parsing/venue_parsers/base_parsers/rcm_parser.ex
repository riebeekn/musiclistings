defmodule MusicListings.Parsing.VenueParsers.BaseParsers.RcmParser do
  @moduledoc """
  Base parser for the Royal Conservatory of Music's rooms (Koerner Hall,
  Mazzoleni Concert Hall and Temerty Theatre), as they all share the one
  rcmusic.com concert listing.
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://www.rcmusic.com"

  @page_size 12

  # The site's pager is a sliding window of five links and under reports the
  # real page count, so we page until a short page arrives rather than trusting
  # it.  This is the backstop on that loop.
  @max_pages 20

  @doc """
  Builds a listing url for one presenter tab / `eventvenue` facet value pair,
  i.e. `build_source_url("Royal Conservatory Concerts", "Koerner Hall")`.
  """
  def build_source_url(presenter_category, venue) do
    query =
      URI.encode_query(tps_activeFacetTab: presenter_category, fq: "eventvenue||#{venue}")

    "#{@base_url}/concerts?#{query}"
  end

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    Selectors.all_matches(body, css("#tps-aws-results .tps-card-item"))
  end

  def next_page_url(body, current_url, source_urls) do
    if body |> events() |> Enum.count() < @page_size do
      next_source_url(current_url, source_urls)
    else
      next_page_of_current_source_url(current_url, source_urls)
    end
  end

  # The page param is edited as a string rather than by rebuilding the query,
  # so the escaping of the facet values is passed through untouched.
  defp next_page_of_current_source_url(current_url, source_urls) do
    case current_page(current_url) do
      page when page >= @max_pages -> next_source_url(current_url, source_urls)
      1 -> "#{current_url}&page=2"
      page -> String.replace(current_url, "&page=#{page}", "&page=#{page + 1}")
    end
  end

  defp current_page(current_url) do
    case Regex.run(~r/&page=(\d+)/, current_url) do
      [_match, page_string] -> String.to_integer(page_string)
      nil -> 1
    end
  end

  defp next_source_url(current_url, source_urls) do
    current_source_url = String.replace(current_url, ~r/&page=\d+/, "")

    case Enum.find_index(source_urls, &(&1 == current_source_url)) do
      nil -> nil
      index -> Enum.at(source_urls, index + 1)
    end
  end

  # The numeric id in the ticket link is the site's own id for the
  # performance, so unlike title + date it survives two performances of the
  # same programme on one day.  Note it can't be taken from the details url -
  # some of those slugs omit it.
  def event_id(event) do
    case ticket_path(event) do
      nil -> fallback_event_id(event)
      ticket_path -> Path.basename(ticket_path)
    end
  end

  # Nothing identifies the free events but their title, and a festival day can
  # carry several identically titled student concerts and master classes, so
  # the time goes into the id too.
  defp fallback_event_id(event) do
    "#{event_title(event)}_#{event_date(event)}_#{event_time(event)}"
    |> ParseHelpers.replace_punctuation_and_spaces()
    |> String.downcase()
  end

  def ignored_event_id(event), do: event_id(event)

  def event_title(event) do
    event
    |> Selectors.text(css(".tps-card-item-title"))
    |> String.trim()
  end

  def performers(event) do
    [event_title(event)] |> Performers.new()
  end

  def event_date(event) do
    [month_string, day_string, year_string | _time] =
      event |> date_and_time_string() |> String.split()

    {:ok, date} =
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)

    date
  end

  def additional_dates(_event), do: []

  def event_time(event) do
    event
    |> date_and_time_string()
    |> then(&Regex.run(~r/\d{1,2}:\d{2}\s*[AP]M/i, &1))
    |> case do
      [time_string] -> ParseHelpers.time_from_time_string(time_string)
      nil -> nil
    end
  end

  # i.e. "Oct 02, 2026 8:00 PM"
  defp date_and_time_string(event) do
    event
    |> Selectors.text(css(".tps-card-item-date-inner"))
    |> String.trim()
  end

  def price(_event), do: Price.unknown()

  def age_restriction(_event), do: :unknown

  def ticket_url(event) do
    case ticket_path(event) do
      nil -> nil
      ticket_path -> ParseHelpers.sanitize_ticket_url("#{@base_url}#{ticket_path}")
    end
  end

  # The free listings aren't ticketed and carry a literal "null" where the
  # performance id would be, i.e. "/tickets/seats/null".
  defp ticket_path(event) do
    event
    |> Selectors.url(css(".tps-card-item-action-info"))
    |> case do
      nil -> nil
      ticket_path -> if Path.basename(ticket_path) == "null", do: nil, else: ticket_path
    end
  end

  def details_url(event) do
    case Selectors.url(event, css(".tps-card-item-title")) do
      nil -> nil
      details_path -> "#{@base_url}#{details_path}"
    end
  end
end
