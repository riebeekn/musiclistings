defmodule MusicListings.Parsing.VenueParsers.DrakeUndergroundParser do
  @moduledoc """
  Parser for extracing events from https://www.thedrake.ca/thedrakehotel/underground/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @drake_underground_location_id 67

  # The event API carries no event date whatsoever - the date lives only on the
  # event's own page, as a label like "Aug. 24, 7:00PM - 10:30PM" that omits the
  # year.  The Drake keeps shows listed for months after they happen, so the
  # year cannot be guessed from the current date: it is resolved against the
  # WordPress publish date of the listing, which always precedes the show.
  # The label lives in the page hero.  The booking widget elsewhere on the page
  # uses the same typography class for its (empty) date placeholder, so the
  # hero is selected first and any other candidate has to look like a date.
  @hero_date_label_selector ".c-hero-edito_content p.u-typo-label-small"
  @date_label_selector "p.u-typo-label-small"
  @date_label_regex ~r/^\s*([A-Za-z]{3,})\.?\s+(\d{1,2})(?:,\s*(\d{1,2}:\d{2}\s*[AP]M))?/i

  # Poster images are often named like "thumbnail_07-July-04-2025-Cicadachar" -
  # a secondary source, but one that carries a real year
  @image_date_regex ~r/\b(January|February|March|April|May|June|July|August|September|October|November|December)[-_](\d{1,2})[-_](\d{4})\b/i

  # No show is booked more than this far ahead of its listing being published;
  # anything beyond it means we've read the wrong thing off the page
  @max_days_after_publish 550

  # The ticket link is the lone button in the page hero, next to the date
  # label.  It points at whichever vendor the promoter used (eventbrite,
  # ticketmaster, admitone, dice, tixr, posh...), so there is nothing to
  # allowlist.  Further down the page the hotel restaurants are cross sold with
  # buttons carrying the same `c-button -alt` classes, so the hero scope and the
  # link text both have to agree before we take a href.
  @ticket_link_selector ".c-hero-edito_content a.c-button[href]"
  @ticket_link_text_regex ~r/\btickets\b/i

  @impl true
  def source_url,
    do:
      "https://thedrake.ca/wp-json/wp/v2/event?event_location=#{@drake_underground_location_id}&per_page=100"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    to_string(event["id"])
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    event["title"]["rendered"]
    |> ParseHelpers.clean_html()
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    case detail_info(event) do
      %{date: %Date{} = date} ->
        date

      _no_date ->
        # Deliberately fail rather than fall back to a guess: a fabricated date
        # publishes a show that isn't happening, which is worse than missing it.
        # The raise is recorded as a parse error and surfaced in the crawl email.
        raise "Unable to determine event date for #{event["link"]}"
    end
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

  # The event page is fetched once per event and memoized: every callback for a
  # given event runs in the same task process (see Crawler.EventParser), so the
  # date, the time and the ticket url cost a single request between them.
  defp detail_info(event) do
    cache_key = {:drake_underground_detail, event["link"]}

    case Process.get(cache_key) do
      nil ->
        info = fetch_detail_info(event)
        Process.put(cache_key, info)
        info

      cached ->
        cached
    end
  end

  defp fetch_detail_info(event) do
    with {:ok, %HttpClient.Response{status: 200, body: body}} <- HttpClient.get(event["link"]),
         {:ok, anchor_date} <- published_on(event) do
      extract_detail_info(body, anchor_date)
    else
      _error -> :error
    end
  end

  defp extract_detail_info(body, anchor_date) do
    document = Meeseeks.parse(body)

    document
    |> date_and_time_from_label(anchor_date)
    |> case do
      %{date: %Date{}} = info -> info
      _no_label_date -> %{date: date_from_image_name(body, anchor_date), time: nil}
    end
    |> Map.put(:ticket_url, extract_ticket_url(document))
  end

  defp extract_ticket_url(document) do
    document
    |> Selectors.all_matches(css(@ticket_link_selector))
    |> Enum.find(&Regex.match?(@ticket_link_text_regex, Selectors.text(&1)))
    |> case do
      nil ->
        nil

      link ->
        link
        |> Selectors.attr("href")
        |> ParseHelpers.sanitize_ticket_url()
    end
  end

  defp date_and_time_from_label(document, anchor_date) do
    case Regex.run(@date_label_regex, date_label(document)) do
      [_match, month_string, day_string | rest] ->
        date =
          month_string
          |> ParseHelpers.build_date_from_month_day_strings_anchored(day_string, anchor_date)
          |> validate_date(anchor_date)

        %{date: date, time: rest |> List.first() |> ParseHelpers.time_from_time_string()}

      _no_match ->
        %{date: nil, time: nil}
    end
  end

  defp date_label(document) do
    document
    |> Selectors.all_matches(css(@hero_date_label_selector))
    |> case do
      [] -> Selectors.all_matches(document, css(@date_label_selector))
      hero_matches -> hero_matches
    end
    |> Selectors.text()
    |> Enum.find("", &Regex.match?(@date_label_regex, &1))
  end

  defp date_from_image_name(body, anchor_date) do
    case Regex.run(@image_date_regex, body) do
      [_match, month_string, day_string, year_string] ->
        year_string
        |> ParseHelpers.build_date_from_year_month_day_strings(month_string, day_string)
        |> validate_date(anchor_date)

      _no_match ->
        nil
    end
  end

  # A listing is always published before the show it advertises, and never much
  # more than a year before, so a date outside that window means we matched
  # something that isn't the event date
  defp validate_date({:ok, date}, anchor_date) do
    earliest = Date.add(anchor_date, -2)
    latest = Date.add(anchor_date, @max_days_after_publish)

    if Date.before?(date, earliest) or Date.after?(date, latest) do
      nil
    else
      date
    end
  end

  defp validate_date(_error, _anchor_date), do: nil

  defp published_on(event) do
    with post_date_string when is_binary(post_date_string) <- event["date"],
         [date_part | _rest] <- String.split(post_date_string, "T"),
         [year_string, month_string, day_string] <- String.split(date_part, "-") do
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
    else
      _error -> {:error, :invalid_date}
    end
  end

  @impl true
  def price(_event) do
    Price.unknown()
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

  @impl true
  def details_url(event) do
    event["link"]
  end
end
