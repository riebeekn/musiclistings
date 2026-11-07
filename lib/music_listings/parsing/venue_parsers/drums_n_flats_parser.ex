defmodule MusicListings.Parsing.VenueParsers.DrumsNFlatsParser do
  @moduledoc """
  Parser for extracting events from https://www.drumsnflats.com/events/live-music/

  The site is on TouchBistro and has no structured listings: the schedule is
  typed by hand into a single "event" description, one show per `<br>` separated
  line, i.e.

      Friday November 13, 9pm - ONLY DADS $10 cover
      Saturday November 14, 9pm - RUDE E BONES $10 advance / $15 door

  so `events/1` turns each line that looks like a show into a map, and the other
  callbacks read from it.  Because it's typed by hand:

  - Lines that don't look like a show (headings, blurbs, typos) are skipped
    rather than failing the crawl, as are open "TBD" dates.
  - The weekday is ignored as it's sometimes wrong, the month and day are used.
  - October is written as "Rocktober".
  - There's no year, so it's inferred from the month and day.

  Shows have no id or page of their own, so the id is built from the date and
  time and every show links to the live music page, where tickets are sold.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://www.drumsnflats.com/events/live-music/"

  # [weekday] month day, time - title [price]
  @show_line ~r/^(?:[a-z]+day\s+)?(?<month>[a-z]+)\.?\s+(?<day>\d{1,2})(?:st|nd|rd|th)?,?\s+(?<time>\d{1,2}(?::\d{2})?\s*[ap]\.?m\.?)\s*[-–—]\s*(?<rest>.+)$/iu
  @price ~r/\s+(?<price>\$\d.*)$/u
  @open_date ~r/^(tbd|tba)\W*$/i

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".list_events .item_description"))
    |> Enum.flat_map(&Selectors.text_lines/1)
    |> Enum.map(&parse_show_line/1)
    |> Enum.reject(&is_nil/1)
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_venue_and_datetime("drums_n_flats", event.date, event.time)
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

  # i.e. "$15 tickets", "$10 cover" or "$10 advance / $15 door"
  @impl true
  def price(%{price: nil}), do: Price.unknown()

  def price(event) do
    event.price
    |> String.replace(~r/tickets?|cover/i, "")
    |> String.replace("/", "-")
    |> Price.new()
  end

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url

  defp parse_show_line(line) do
    with %{"month" => month, "day" => day, "time" => time, "rest" => rest} <-
           Regex.named_captures(@show_line, line),
         {:ok, date} <-
           month |> month_name() |> ParseHelpers.build_date_from_month_day_strings(day),
         {:ok, time} <- ParseHelpers.build_time_from_time_string(time),
         {title, price} <- split_price(rest),
         false <- title == "" or title =~ @open_date do
      %{date: date, time: time, title: title, price: price}
    else
      _not_a_show -> nil
    end
  end

  defp month_name(month) do
    case String.downcase(month) do
      "rocktober" -> "october"
      month -> month
    end
  end

  defp split_price(rest) do
    case Regex.split(@price, rest, parts: 2, include_captures: true, trim: true) do
      [title, price] -> {String.trim(title), String.trim(price)}
      [title] -> {String.trim(title), nil}
    end
  end
end
