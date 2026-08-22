defmodule MusicListings.Parsing.VenueParsers.Bsmt254Parser do
  @moduledoc """
  Parser for extracing events from https://www.bsmt254.com
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  # The listing carries no ticket link, no start time and no price - its date
  # cell reads "12:00 am" for every event - so all three come from the event's
  # own page, where they sit in two meta spans and a lone button:
  #
  #   <span class='eventMeta'> / 8pm</span>
  #   <span class='eventMeta'> / $15 Adv / $20 Door</span>
  #   <a class='button' href='...'>Tickets</a>
  #
  # The button points at whichever vendor the promoter used (eventbrite, dice,
  # ra.co, posh, ticketgateway...), so there is nothing to allowlist.
  @ticket_link_selector "a.button[href]"
  @event_meta_selector ".eventMeta"

  # Each meta span is written as " / 8pm"
  @meta_separator_regex ~r{^\s*/\s*}

  # The venue writes its tiers with slashes ("$12 adv / $15 door") and an open
  # ended price in words ("$20 and up").  Price.new/1 splits on commas and
  # dashes and reads a trailing plus as open ended, so both are rewritten to the
  # forms it already knows.  It looks for "pwyc" before any of that, so
  # "$15/PWYC" is unaffected.
  #
  # Only a slash that introduces another amount counts: these blurbs also run to
  # prose, and "Proceeds support ... / 7\" release" is a record, not a $7 tier.
  @open_ended_price_regex ~r/\s*\band up\b/i
  @price_tier_separator_regex ~r{\s*/\s*(?=\$)}

  @impl true
  def source_url, do: "https://www.bsmt254.com/events/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".homeEventWrap"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".eventDetails h3"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [month, day, year, _time, _ampm] = Selectors.text(event, css(".datePull")) |> String.split()

    {:ok, date} = ParseHelpers.build_date_from_year_month_day_strings(year, month, day)
    date
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    case detail_info(event) do
      %{time: time} -> time
      _no_time -> nil
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
  def age_restriction(_event) do
    :unknown
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
  # time, the price and the ticket url cost a single request between them.
  defp detail_info(event) do
    details_url = details_url(event)
    cache_key = {:bsmt_254_detail, details_url}

    case Process.get(cache_key) do
      nil ->
        info = fetch_detail_info(details_url)
        Process.put(cache_key, info)
        info

      cached ->
        cached
    end
  end

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
        meta = event_meta(document)

        %{
          ticket_url: extract_ticket_url(document),
          time: meta |> Enum.at(0) |> extract_time(),
          price: meta |> Enum.at(1) |> extract_price()
        }

      _unparseable ->
        :error
    end
  end

  # Indexed rather than destructured so a page rendering a different number of
  # spans loses the extras instead of raising.
  defp event_meta(document) do
    document
    |> Selectors.all_matches(css(@event_meta_selector))
    |> Selectors.text()
    |> Enum.map(&String.replace(&1, @meta_separator_regex, ""))
  end

  defp extract_ticket_url(document) do
    document
    |> Selectors.url(css(@ticket_link_selector))
    |> ParseHelpers.sanitize_ticket_url()
  end

  defp extract_time(time_string) do
    case ParseHelpers.build_time_from_time_string(time_string) do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  defp extract_price(nil), do: Price.unknown()

  defp extract_price(price_string) do
    price_string
    |> String.replace(@open_ended_price_regex, "+")
    |> String.replace(@price_tier_separator_regex, ",")
    |> Price.new()
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".homeEventWrap"))
  end
end
