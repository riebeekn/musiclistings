defmodule MusicListings.Parsing.VenueParsers.HughsRoomParser do
  @moduledoc """
  Parser for extracing events from https://hughsroomlive.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://hughsroomlive.com/on-stage/?page_number=1"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def example_data_file_location, do: "test/data/hughs_room/index.html"

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".showpass-event-card"))
  end

  @impl true
  def next_page_url(body, current_url) do
    current_page = get_current_page_number(current_url)

    if current_page do
      last_page =
        body
        |> Selectors.all_matches(css(".showpass-pagination li a"))
        |> Selectors.text()
        |> List.last()
        |> String.to_integer()

      if current_page >= last_page do
        nil
      else
        "https://hughsroomlive.com/on-stage/?page_number=#{current_page + 1}"
      end
    else
      nil
    end
  end

  defp get_current_page_number(url) do
    uri = URI.parse(url)
    query_params = URI.decode_query(uri.query)

    case Map.get(query_params, "page_number") do
      nil -> nil
      page_number -> String.to_integer(page_number)
    end
  end

  @impl true
  def event_id(event) do
    event
    |> Selectors.match_one(css(".action-bar a.open-ticket-widget"))
    |> Selectors.attr("id")
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(".showpass-event-title h3"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week, month_string, day_string, year_string] =
      event
      |> Selectors.text(css(".showpass-detail-event-date .start-date .day"))
      |> if_nil_try_alternate_date_selector(event)
      |> String.split()

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  defp if_nil_try_alternate_date_selector(nil = _captured_value, event) do
    Selectors.text(event, css(".showpass-detail-event-date .info i.fa-calendar + span"))
  end

  defp if_nil_try_alternate_date_selector(captured_value, _event), do: captured_value

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css(".showpass-detail-event-date .start-date .time"))
    |> if_nil_try_alternate_time_selector(event)
    |> ParseHelpers.build_time_from_time_string()
  end

  defp if_nil_try_alternate_time_selector(nil = _captured_value, event) do
    Selectors.text(event, css(".showpass-detail-event-date .info i.fa-clock-o + span"))
  end

  defp if_nil_try_alternate_time_selector(captured_value, _event), do: captured_value

  @impl true
  def price(event) do
    event
    |> Selectors.text(css(".showpass-price-display"))
    |> Price.new()
  end

  @impl true
  def age_restriction(_event) do
    :unknown
  end

  @impl true
  def ticket_url(event) do
    event_id = event_id(event)
    "https://www.showpass.com/#{event_id}"
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
