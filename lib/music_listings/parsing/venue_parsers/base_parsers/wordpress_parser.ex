defmodule MusicListings.Parsing.VenueParsers.BaseParsers.WordpressParser do
  @moduledoc """
  Base parser for wix sites
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
    |> Selectors.match_one(css("script[type=\"application/ld+json\"]"))
    |> Selectors.data()
    |> case do
      nil -> []
      events -> Jason.decode!(events)
    end
  end

  def next_page_url(_body, current_url) do
    current_page = get_current_page_number(current_url)

    cond do
      current_page == nil ->
        "#{current_url}list/page/2/"

      current_page && current_page <= 3 ->
        next_page = current_page + 1
        String.replace(current_url, "page/#{current_page}", "page/#{next_page}")

      true ->
        nil
    end
  end

  defp get_current_page_number(url) do
    regex = ~r/page\/(\d+)\/?$/

    case Regex.run(regex, url) do
      [_text, page_number] -> String.to_integer(page_number)
      _no_page_number -> nil
    end
  end

  def event_id(event, venue_name) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime(venue_name, date, time)
  end

  def event_title(event) do
    event["name"]
    |> ParseHelpers.fix_encoding()
  end

  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  def event_date(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_date()
  end

  def additional_dates(_event) do
    []
  end

  def event_time(event) do
    event["startDate"]
    |> NaiveDateTime.from_iso8601!()
    |> NaiveDateTime.to_time()
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
    event["url"]
  end
end
