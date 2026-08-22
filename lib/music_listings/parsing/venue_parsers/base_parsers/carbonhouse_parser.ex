defmodule MusicListings.Parsing.VenueParsers.BaseParsers.CarbonhouseParser do
  @moduledoc """
  Base parser for sites using
  the https://www.carbonhouse.com/ platform
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
    |> ParseHelpers.clean_html()
    |> Selectors.all_matches(css(".eventItem:not(.team)"))
    |> Enum.reject(&(toronto_sceptres_event?(&1) or toronto_tempo_event?(&1)))
  end

  defp toronto_sceptres_event?(event_item) do
    event_item
    |> Selectors.text(css(".title"))
    |> String.contains?("Toronto Sceptres")
  end

  defp toronto_tempo_event?(event_item) do
    event_item
    |> Selectors.text(css(".title"))
    |> String.contains?("Toronto Tempo")
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @doc """
  Offset-based pagination for Carbonhouse `events_ajax/<offset>` endpoints.

  The trailing path number is a row offset; an out-of-range offset returns an
  empty page. We advance the offset by the actual number of `.eventItem` rows on
  the current page and stop once a page comes back with no events.
  """
  def next_page_url_by_offset(body, current_url) do
    event_count =
      body
      |> ParseHelpers.clean_html()
      |> Selectors.all_matches(css(".eventItem"))
      |> Enum.count()

    if event_count == 0 do
      nil
    else
      next_offset = current_offset(current_url) + event_count
      String.replace(current_url, ~r{/events_ajax/\d+}, "/events_ajax/#{next_offset}")
    end
  end

  defp current_offset(current_url) do
    [_match, offset_string] = Regex.run(~r{/events_ajax/(\d+)}, current_url)
    String.to_integer(offset_string)
  end

  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  def ignored_event_id(event) do
    event_id(event)
  end

  def event_title(event, opts \\ []) do
    selector_string = maybe_add_prefix("title", opts)

    event
    |> Selectors.text(css(selector_string))
    |> ParseHelpers.fix_encoding()
  end

  defp maybe_add_prefix(selector_string, opts) do
    opts
    |> Keyword.get(:prefix)
    |> case do
      nil -> ".#{selector_string}"
      prefix -> ".#{prefix}#{selector_string}"
    end
  end

  def performers(event) do
    event
    |> Selectors.all_matches(css(".title"))
    |> Selectors.text()
    |> Enum.map(&ParseHelpers.fix_encoding/1)
    |> Performers.new()
  end

  def event_date(event) do
    day_string = Selectors.text(event, css(".m-date__day"))
    month_string = Selectors.text(event, css(".m-date__month"))
    year_string = Selectors.text(event, css(".m-date__year"))

    {:ok, date} =
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)

    date
  end

  def additional_dates(event) do
    [_first_date | additional_dates] = Selectors.all_matches(event, css(".m-date__day"))

    if additional_dates == [] do
      []
    else
      month_string = Selectors.text(event, css(".m-date__month"))
      year_string = Selectors.text(event, css(".m-date__year"))

      additional_dates
      |> Enum.map(fn additional_date ->
        day_string = additional_date |> Selectors.text(css(".m-date__day"))

        {:ok, date} =
          ParseHelpers.build_date_from_year_month_day_strings(
            year_string,
            month_string,
            day_string
          )

        date
      end)
    end
  end

  def event_time(event) do
    case event
         |> Selectors.text(css(".start"))
         |> ParseHelpers.build_time_from_time_string() do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    event
    |> Selectors.url(css(".tickets"))
    |> with_scheme()
  end

  # A run of shows sells each night separately, so the listing has no single
  # link to give: it renders "Buy Tickets" as an unclickable span (class
  # `no_ticket_link`) and puts a link per night on the event's own page.  Note
  # Selectors.url/2 reads an href off whatever it matches, so that span yields
  # nil rather than an error - the dates simply arrive with no ticket url.
  def ticket_url(event, date) do
    case ticket_url(event) do
      nil -> showing_ticket_url(event, date)
      listed_url -> listed_url
    end
  end

  def details_url(event) do
    Selectors.url(event, css(".more"))
  end

  defp showing_ticket_url(event, date) do
    event
    |> showings()
    |> Enum.find_value(fn {showing_date, url} ->
      if Date.compare(showing_date, date) == :eq, do: url
    end)
  end

  # The event page is fetched once per event and memoized: ticket_url/2 is
  # called once per date (see Crawler.EventParser), so a run of shows costs a
  # single request between all of its nights.
  defp showings(event) do
    details_url = details_url(event)
    cache_key = {:carbonhouse_showings, details_url}

    case Process.get(cache_key) do
      nil ->
        showings = fetch_showings(details_url)
        Process.put(cache_key, showings)
        showings

      cached ->
        cached
    end
  end

  defp fetch_showings(details_url) when is_binary(details_url) and details_url != "" do
    case HttpClient.get(details_url, [], max_retries: 1) do
      {:ok, %HttpClient.Response{status: 200, body: body}} -> parse_showings(body)
      _error -> []
    end
  end

  defp fetch_showings(_no_details_url), do: []

  defp parse_showings(body) do
    case body |> ParseHelpers.clean_html() |> Meeseeks.parse() do
      %Meeseeks.Document{} = document ->
        document
        |> Selectors.all_matches(css(".event_showings .listItem"))
        |> Enum.flat_map(&showing/1)

      _unparseable ->
        []
    end
  end

  defp showing(listing) do
    with %Date{} = date <- showing_date(listing),
         url when is_binary(url) <- listing |> Selectors.url(css(".tickets")) |> with_scheme() do
      [{date, url}]
    else
      _no_showing -> []
    end
  end

  # A vendor link is occasionally entered with the scheme left off, ie.
  # "ticketmaster.ca/..." - stored as is it would resolve against our own domain
  # rather than the vendor's.
  defp with_scheme(nil), do: nil
  defp with_scheme("http://" <> _rest = url), do: url
  defp with_scheme("https://" <> _rest = url), do: url
  defp with_scheme("//" <> rest), do: "https://#{rest}"
  defp with_scheme("/" <> _rest = path), do: path

  defp with_scheme(url) do
    if url |> String.split("/") |> List.first() |> String.contains?(".") do
      "https://#{url}"
    else
      url
    end
  end

  defp showing_date(listing) do
    day_string = Selectors.text(listing, css(".m-date__day"))
    month_string = Selectors.text(listing, css(".m-date__month"))
    year_string = Selectors.text(listing, css(".m-date__year"))

    case ParseHelpers.build_date_from_year_month_day_strings(
           year_string,
           month_string,
           day_string
         ) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end
end
