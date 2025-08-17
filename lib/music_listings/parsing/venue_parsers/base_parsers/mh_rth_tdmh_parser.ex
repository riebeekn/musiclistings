defmodule MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser do
  @moduledoc """
  Base parser for Massey Hall, Roy Thomson Hall and
  TD Music Hall, as they are on a single site
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    body
    |> Selectors.all_matches(css(".c-card--event"))
  end

  def next_page_url(_body, current_url) do
    current_page =
      current_url
      |> URI.parse()
      |> Map.get(:query)
      |> URI.decode_query()
      |> Map.get("page")
      |> String.to_integer()

    if current_page < 5 do
      current_page_string = Integer.to_string(current_page)
      next_page_string = (current_page + 1) |> Integer.to_string()
      String.replace(current_url, current_page_string, next_page_string)
    else
      nil
    end
  end

  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  def ignored_event_id(event), do: event_id(event)

  def event_title(event) do
    Selectors.text(event, css(".c-card__title"))
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    [first | _remaining_dates] =
      event
      |> event_dates()
      |> String.split(" - ", trim: true)

    Date.from_iso8601!(first)
  end

  def additional_dates(event) do
    event
    |> event_dates()
    |> String.split(" - ", trim: true)
    |> case do
      [_no_additional_dates] ->
        []

      [start_date_string, end_date_string] ->
        start_date = Date.from_iso8601!(start_date_string)
        end_date = Date.from_iso8601!(end_date_string)

        start_date
        |> Date.range(end_date)
        # skip the first (primary) date
        |> Enum.drop(1)
        |> Enum.to_list()
    end
  end

  defp event_dates(event) do
    event
    |> Selectors.match_one(css(".c-card__time time"))
    |> Selectors.attr("datetime")
  end

  def event_time(_event) do
    nil
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(_event) do
    nil
  end

  def details_url(event) do
    event
    |> Selectors.match_one(css(".c-card__cover-link"))
    |> Selectors.attr("href")
  end
end
