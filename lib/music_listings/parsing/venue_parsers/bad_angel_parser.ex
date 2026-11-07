defmodule MusicListings.Parsing.VenueParsers.BadAngelParser do
  @moduledoc """
  Parser for extracting events from https://www.badangelbar.com/

  The site is hand written HTML with a page per month, e.g. `musicnovember2026.html`,
  linked from the home page's "Music and Events" heading.  `retrieve_events_fun/0`
  therefore fetches the home page, follows that link and returns the month's page.

  The month's page is a weekly rundown: an `<h2>` per weekday, an `<h3>` per series
  on that day (usually carrying the time), then a `<p>` per show, i.e.

      <h2>Sundays</h2>
      <h3>Afternoon Jazz Trios:<br/>4-7pm</h3>
      <p><em>A rotating cast of talented musicians...</em></p>
      <p>November 1 - Wade Pollesel Trio</p>

  so `events/1` walks the page's elements in order, carrying the series' time
  down to each `November 1 - ...` line, which it turns into a map.  Because it's
  typed by hand:

  - A series' time can also be in a later paragraph, e.g. `(5:30-7:30)`, and a show
    can override it inline, e.g. `November 7 - Julian Fauth (4:30-6:30)`.
  - Times rarely say am or pm.  The bar opens in the afternoon, so pm is assumed
    unless a range shows otherwise, e.g. `11-2pm`.
  - Weekly series without dated shows (open stage, jazz jams) are skipped.
  - The show lines have no year, it's taken from the page's title
    (`Bad Angel Music November 2026`).

  Shows have no id or page of their own, so the id is built from the date and time
  and every show links to the home page (the month's page goes away next month).
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://www.badangelbar.com/"

  @music_link_text ~r/music/i
  @page_month ~r/(?<month>[a-z]+)\s+(?<year>20\d{2})/iu
  # month day - title
  @show_line ~r/^(?<month>[a-z]+)\.?\s+(?<day>\d{1,2})(?:st|nd|rd|th)?\s*[-–—]\s*(?<rest>.+)$/iu
  @parenthetical ~r/\s*\((?<inner>[^)]*)\)/u
  @time ~r/(?<start>\d{1,2}(?::\d{2})?)\s*(?<start_ap>[ap]\.?m\.?)?(?<range>\s*[-–]\s*(?:late|(?<end>\d{1,2})(?::\d{2})?\s*(?<end_ap>[ap]\.?m\.?)?))?/iu

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url ->
      with {:ok, %Response{status: 200, body: body}} <- HttpClient.get(url),
           {:ok, music_url} <- music_page_url(body, url) do
        HttpClient.get(music_url)
      end
    end
  end

  @impl true
  def events(body) do
    with {:ok, document} <- Selectors.parse(body) do
      page_month = page_month(document)

      document
      |> Selectors.all_matches(css("body > div > *"))
      |> Enum.reduce({nil, []}, &collect_show(&1, &2, page_month))
      |> elem(1)
      |> Enum.reverse()
    end
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_venue_and_datetime("bad_angel", event.date, event.time)
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event.title

  @impl true
  def performers(event) do
    [event.title]
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: event.date

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event.time

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url

  defp music_page_url(body, url) do
    body
    |> Selectors.all_matches(css("a[href$=\".html\"]"))
    |> Enum.find(&(Selectors.text(&1) =~ @music_link_text))
    |> case do
      nil -> {:error, :music_page_link_not_found}
      link -> {:ok, url |> URI.merge(Selectors.attr(link, "href")) |> URI.to_string()}
    end
  end

  # The first of the page's month, or nil if the title doesn't say
  defp page_month(document) do
    title = document |> Selectors.match_one(css("title")) |> Selectors.text()

    with true <- is_binary(title),
         %{"month" => month, "year" => year} <- Regex.named_captures(@page_month, title),
         {:ok, date} <- ParseHelpers.build_date_from_year_month_day_strings(year, month, "1") do
      date
    else
      _no_month -> nil
    end
  end

  # Walks the page carrying the current series' time: a weekday heading resets it,
  # a series heading sets it, and a paragraph either is a show or may carry it.
  defp collect_show(element, {series_time, shows}, page_month) do
    text = element |> Selectors.text() |> String.trim()

    case Selectors.tag(element) do
      "h2" ->
        {nil, shows}

      "h3" ->
        {find_time(text), shows}

      "p" ->
        case parse_show_line(text, series_time, page_month) do
          nil -> {series_time || parenthetical_time(text), shows}
          show -> {series_time, [show | shows]}
        end

      _other ->
        {series_time, shows}
    end
  end

  defp parse_show_line(line, series_time, page_month) do
    with %{"month" => month, "day" => day, "rest" => rest} <-
           Regex.named_captures(@show_line, line),
         {:ok, date} <- build_date(month, day, page_month),
         {title, inline_time} <- split_time(rest),
         false <- title == "" do
      %{date: date, time: inline_time || series_time, title: title}
    else
      _not_a_show -> nil
    end
  end

  defp build_date(month, day, nil), do: ParseHelpers.build_date_from_month_day_strings(month, day)

  # The year is the page's, unless the show is across a new year from the page's month
  defp build_date(month, day, page_month) do
    with {:ok, date} <-
           ParseHelpers.build_date_from_year_month_day_strings("#{page_month.year}", month, day) do
      cond do
        Date.diff(date, page_month) < -180 -> {:ok, Date.shift(date, year: 1)}
        Date.diff(date, page_month) > 180 -> {:ok, Date.shift(date, year: -1)}
        true -> {:ok, date}
      end
    end
  end

  # Splits an inline time off a show's title, e.g. "Julian Fauth (4:30-6:30)"
  defp split_time(rest) do
    case Regex.named_captures(@parenthetical, rest) do
      %{"inner" => inner} ->
        case find_time(inner) do
          nil ->
            {String.trim(rest), nil}

          time ->
            {rest |> String.replace(@parenthetical, "", global: false) |> String.trim(), time}
        end

      nil ->
        {String.trim(rest), nil}
    end
  end

  defp parenthetical_time(text) do
    case Regex.named_captures(@parenthetical, text) do
      %{"inner" => inner} -> find_time(inner)
      nil -> nil
    end
  end

  # The first time in the text, e.g. "4-7pm", "8pm" or "9:00-late".  A bare number
  # (e.g. "$15") isn't a time, it needs an am/pm, minutes or a range.
  defp find_time(text) do
    @time
    |> Regex.scan(text, capture: :first)
    |> Enum.find_value(fn [match] ->
      captures = Regex.named_captures(@time, match)

      if captures["start_ap"] != "" or captures["start"] =~ ":" or captures["range"] != "" do
        build_time(captures)
      end
    end)
  end

  defp build_time(%{"start" => start} = captures) do
    ParseHelpers.time_from_time_string("#{start} #{meridiem(captures)}")
  end

  defp meridiem(%{"start_ap" => start_ap}) when start_ap != "", do: clean_meridiem(start_ap)

  # e.g. "11-2pm" starts in the morning
  defp meridiem(%{"start" => start, "end" => end_hour, "end_ap" => end_ap}) when end_ap != "" do
    {start_hour, _minutes} = Integer.parse(start)

    if start_hour > String.to_integer(end_hour) and start_hour != 12,
      do: "am",
      else: clean_meridiem(end_ap)
  end

  defp meridiem(_captures), do: "pm"

  defp clean_meridiem(meridiem) do
    meridiem
    |> String.replace(".", "")
    |> String.downcase()
  end
end
