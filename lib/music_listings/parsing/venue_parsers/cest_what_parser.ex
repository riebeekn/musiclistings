defmodule MusicListings.Parsing.VenueParsers.CestWhatParser do
  @moduledoc """
  Parser for extracting events from https://cestwhat.com/

  The venue publishes its shows as a monthly poster image, "What's Up", on its home
  page.  The image's alt text spells the poster out, e.g.

      WHAT'S UP NOVEMBER 07 SAT FOOL HEARTS 8PM-11PM | PWYC 13 FRI HONEST LIARS
      9PM-12AM | PWYC ... WEEKLY C'EST WHAT? TRIVIA! Wednesdays at 7 PM

  and its title names the month, e.g. `November 2026 Event Calendar`.  The text is
  typed by hand and its layout changes from poster to poster, so two are handled:

  - day, weekday, title, time range, optional price:
    `07 SAT FOOL HEARTS 8PM-11PM | PWYC` (from October 2026)
  - month, day, title, time range: `APR 10 Honest Liars | 9pm-12am` (earlier in 2026)

  A show's year is the one in the image's title, else the next time its month comes
  round (as it is for a show from outside the poster's month).  A time range often only gives am / pm on its end, e.g. `3-6pm`, so the
  start borrows it.  The weekly trivia night isn't in either layout, so it's skipped.

  Shows have no id or page of their own, so the id is built from the date and time
  (two shows can share a day) and every show links to the home page.

  The `/event-poster/` page this used to read stopped being updated in September
  2026.  The venue's ticket store (music.cestwhat.com) and Eventbrite page were empty
  when checked.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://cestwhat.com/"

  @poster_alt ~r/what'?s\s+up/iu
  @poster_month ~r/\b(?<month>jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sept?(?:ember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b(?:\s+(?<year>20\d{2}))?/iu

  @time "\\d{1,2}(?::\\d{2})?\\s*(?:am|pm)?"
  @time_range "(?<start_time>#{@time})\\s*-\\s*(?<end_time>#{@time})"
  @price "(?:\\s*\\|\\s*(?<price>pwyc|free|\\$\\s*\\d+(?:\\.\\d{2})?))?"

  # 07 SAT FOOL HEARTS 8PM-11PM | PWYC
  @day_first Regex.compile!(
               "\\b(?<day>\\d{1,2})\\s+(?:mon|tues?|wed|thur?s?|fri|sat|sun)\\s+(?<title>.+?)\\s+#{@time_range}#{@price}",
               "iu"
             )
  # APR 10 Honest Liars | 9pm-12am
  @month_first Regex.compile!(
                 "\\b(?<month>jan|feb|mar|apr|may|jun|jul|aug|sept?|oct|nov|dec)\\s+(?<day>\\d{1,2})\\s+(?<title>.*?)\\s*\\|\\s*#{@time_range}",
                 "iu"
               )

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    with {:ok, document} <- Selectors.parse(body) do
      document
      |> Selectors.all_matches(css("img[alt]"))
      |> Enum.find(&(Selectors.attr(&1, "alt") =~ @poster_alt))
      |> case do
        nil -> []
        poster -> poster_shows(poster)
      end
    end
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_venue_and_datetime("cest_what", event.date, event.time)
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event.title

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: event.date

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event.time

  @impl true
  def price(event), do: Price.new(event.price)

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url

  defp poster_shows(poster) do
    alt = poster |> Selectors.attr("alt") |> ParseHelpers.clean_html() |> collapse_whitespace()
    title = (Selectors.attr(poster, "title") || "") |> ParseHelpers.clean_html()

    # The title names the month and year; the alt text only the month
    poster_month = poster_month(title) || poster_month(alt)

    case Regex.scan(@day_first, alt, capture: :all_names) do
      [] ->
        @month_first
        |> Regex.scan(alt, capture: :all_names)
        |> Enum.map(&month_first_show(&1, poster_month))

      matches ->
        Enum.map(matches, &day_first_show(&1, poster_month))
    end
    |> Enum.reject(&is_nil/1)
  end

  # Captures come back in alphabetical order of their names
  defp day_first_show([day, end_time, price, start_time, title], {month, year}) do
    build_show(month, day, year, title, start_time, end_time, price)
  end

  defp day_first_show(_captures, nil), do: nil

  defp month_first_show([day, end_time, month, start_time, title], poster_month) do
    build_show(month, day, poster_year(poster_month, month), title, start_time, end_time, nil)
  end

  # The poster's year, if the show is in the poster's month
  defp poster_year({poster_month, year}, month) do
    if month_number(poster_month) == month_number(month), do: year
  end

  defp poster_year(nil, _month), do: nil

  defp month_number(month) do
    case ParseHelpers.build_date_from_year_month_day_strings("2000", month, "1") do
      {:ok, date} -> date.month
      _invalid -> nil
    end
  end

  defp build_show(month, day, year, title, start_time, end_time, price) do
    case build_date(month, day, year) do
      {:ok, date} ->
        %{
          date: date,
          time: start_time |> with_meridiem(end_time) |> ParseHelpers.time_from_time_string(),
          title: String.trim(title),
          price: price
        }

      _invalid_date ->
        nil
    end
  end

  defp build_date(month, day, nil), do: ParseHelpers.build_date_from_month_day_strings(month, day)

  defp build_date(month, day, year),
    do: ParseHelpers.build_date_from_year_month_day_strings(year, month, day)

  defp poster_month(text) do
    case Regex.named_captures(@poster_month, text) do
      %{"month" => month, "year" => ""} -> {month, nil}
      %{"month" => month, "year" => year} -> {month, year}
      nil -> nil
    end
  end

  # "3-6pm" -> "3pm"
  defp with_meridiem(start_time, end_time) do
    if start_time =~ ~r/[ap]m/i do
      start_time
    else
      meridiem = if end_time =~ ~r/am/i, do: "am", else: "pm"
      String.trim(start_time) <> meridiem
    end
  end

  defp collapse_whitespace(text), do: text |> String.replace(~r/\s+/u, " ") |> String.trim()
end
