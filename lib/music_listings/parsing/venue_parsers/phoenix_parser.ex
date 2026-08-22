defmodule MusicListings.Parsing.VenueParsers.PhoenixParser do
  @moduledoc """
  Parser for extracing events from https://thephoenixconcerttheatre.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @ticket_link_selector "a.btn-event[href]"
  @price_selector ".ticket-prices .price"

  # The venue writes an open ended price as "$19 and up", which Price.new/1
  # reads as a fixed $19 - it only recognizes the trailing plus form.
  @open_ended_price_regex ~r/\s*and up\b/i

  @impl true
  def source_url, do: "https://thephoenixconcerttheatre.com/events/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".event-item"))
  end

  @impl true
  def next_page_url(body, _current_url) do
    Selectors.url(body, css(".pagination .older a"))
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("phoenix", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".event-title a"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_day_of_week_string, month_day_string, _doors_string] =
      event
      |> Selectors.text(css(".event-date"))
      |> String.split(", ")

    [month_string, day_string] = String.split(month_day_string)

    {:ok, date} = ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
    date
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    [_day_of_week_string, _month_day_string, doors_string] =
      event
      |> Selectors.text(css(".event-date"))
      |> String.split(", ")

    case doors_string
         |> String.replace("Doors: ", "")
         |> ParseHelpers.build_time_from_time_string() do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  @impl true
  def price(event) do
    case detail_info(event) do
      %{price: %Price{} = price} -> price
      _no_price -> Price.unknown()
    end
  end

  @impl true
  def age_restriction(event) do
    event
    |> Selectors.text(css(".event-ages"))
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event) do
    case detail_info(event) do
      %{ticket_url: ticket_url} -> ticket_url
      _no_ticket_url -> nil
    end
  end

  # The event page is fetched once per event and memoized: every callback for a
  # given event runs in the same task process (see Crawler.EventParser), so the
  # ticket url and the price cost a single request between them.
  defp detail_info(event) do
    details_url = details_url(event)
    cache_key = {:phoenix_detail, details_url}

    case Process.get(cache_key) do
      nil ->
        info = fetch_detail_info(details_url)
        Process.put(cache_key, info)
        info

      cached ->
        cached
    end
  end

  # Only an enrichment - the title, date, time and age all come from the index -
  # so one retry and no more.
  defp fetch_detail_info(details_url) when is_binary(details_url) and details_url != "" do
    case HttpClient.get(details_url, [], max_retries: 1) do
      {:ok, %HttpClient.Response{status: 200, body: body}} -> extract_detail_info(body)
      _error -> :error
    end
  end

  defp fetch_detail_info(_no_details_url), do: :error

  defp extract_detail_info(body) do
    case Meeseeks.parse(body) do
      %Meeseeks.Document{} = document ->
        %{ticket_url: extract_ticket_url(document), price: extract_price(document)}

      _unparseable ->
        :error
    end
  end

  defp extract_ticket_url(document) do
    document
    |> Selectors.url(css(@ticket_link_selector))
    |> ParseHelpers.sanitize_ticket_url()
  end

  defp extract_price(document) do
    document
    |> Selectors.match_one(css(@price_selector))
    |> case do
      nil ->
        Price.unknown()

      price ->
        price
        |> Selectors.text()
        |> String.replace(@open_ended_price_regex, "+")
        |> Price.new()
    end
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".event-title a"))
  end
end
