defmodule MusicListings.Parsing.VenueParsers.BowlParser do
  @moduledoc """
  Parser for extracing events from https://www.liveatthebowl.com

  The shows are not a SquareSpace event collection - they are a hand maintained
  SquareSpace list section which embeds its items as JSON in the section's
  `data-current-context` attribute. Each item's date, age restriction and start
  time live in a free text description, ie:

    AUGUST 23, 2026 | ALL AGES<br>6:00PM
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @base_url "https://www.liveatthebowl.com"

  # ie. "AUGUST 23, 2026" or "AUGUST 28 & 29, 2026" for multi day events
  @date_regex ~r/^([A-Za-z]+)\s+([\d\s&]+),\s*(\d{4})$/

  # The show pages label their ticket link either "BUY TICKETS" or "GET
  # TICKETS".  Matching on the link text (rather than taking the first ticket
  # vendor link) skips the "MEET & GREET" upsell some shows list alongside it,
  # which is an add on that does not include a base ticket.
  @ticket_link_text_regex ~r/\b(buy|get)\s+tickets\b/i

  # The show pages list both times, ie. "DOORS: 6:00PM  |  SHOW: 6:30PM"
  @show_time_regex ~r/SHOW:\s*(\d{1,2}:\d{2}\s*[AP]\.?M\.?)/i

  # Each event's show page is fetched once, when the events are parsed, and what
  # we resolve from it is stashed on the event under these keys
  @ticket_url_key "resolved_ticket_url"
  @show_time_key "resolved_show_time"

  @impl true
  def source_url, do: "#{@base_url}/upcoming-shows"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css("[data-controller=\"UserItemsListSimple\"]"))
    |> Enum.flat_map(fn section ->
      section
      |> Selectors.attr("data-current-context")
      |> ParseHelpers.maybe_decode!()
      |> Map.get("userItems", [])
    end)
    |> Enum.map(&Map.merge(&1, retrieve_show_page_details(&1)))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    # no next page - all shows are on the upcoming shows page
    nil
  end

  @impl true
  def event_id(event) do
    event
    |> event_title()
    |> ParseHelpers.build_id_from_title_and_date(event_date(event))
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event["title"]
    |> ParseHelpers.fix_encoding()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    event
    |> dates()
    |> List.first()
  end

  @impl true
  def additional_dates(event) do
    event
    |> dates()
    |> Enum.drop(1)
  end

  # The time on the upcoming shows page is not consistently the start time -
  # for some shows it is the doors time - so prefer the show time the show page
  # states, and only fall back to the listed time when we have no show page.
  @impl true
  def event_time(event) do
    case event[@show_time_key] do
      nil -> listed_time(event)
      show_time -> show_time
    end
  end

  defp listed_time(event) do
    event
    |> description_lines()
    |> Enum.at(1)
    |> ParseHelpers.build_time_from_time_string()
    |> case do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(event) do
    event
    |> date_line_parts()
    |> Enum.at(1)
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  @impl true
  def ticket_url(event), do: event[@ticket_url_key]

  @impl true
  def details_url(event) do
    case event["button"]["buttonLink"] do
      nil -> nil
      button_link -> "#{@base_url}#{button_link}"
    end
  end

  # The upcoming shows page only links to each show's own page - the ticket
  # vendor link and the show time both live on that page, so fetch it once and
  # pick up both.  An event whose show page we can't fetch falls back to what
  # the upcoming shows page told us.
  defp retrieve_show_page_details(event) do
    with details_url when is_binary(details_url) <- details_url(event),
         {:ok, %HttpClient.Response{status: 200, body: body}} <- HttpClient.get(details_url) do
      %{
        @ticket_url_key => extract_ticket_url(body),
        @show_time_key => extract_show_time(body)
      }
    else
      _no_show_page -> %{}
    end
  end

  defp extract_show_time(body) do
    with [_match, time_string] <- Regex.run(@show_time_regex, body),
         {:ok, time} <- ParseHelpers.build_time_from_time_string(time_string) do
      time
    else
      _no_show_time -> nil
    end
  end

  defp extract_ticket_url(body) do
    body
    |> Selectors.all_matches(css("a[href]"))
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

  # A multi day event (ie. "AUGUST 28 & 29, 2026") lists each of its days, the
  # first is the event date and the rest are additional dates.
  defp dates(event) do
    with [date_string | _rest] <- date_line_parts(event),
         [_match, month_string, days_string, year_string] <-
           Regex.run(@date_regex, date_string || "") do
      days_string
      |> String.split("&")
      |> Enum.map(&String.trim/1)
      |> Enum.map(
        &ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, &1)
      )
      |> Enum.flat_map(fn
        {:ok, date} -> [date]
        {:error, _reason} -> []
      end)
    else
      _no_date -> []
    end
  end

  # ie. ["AUGUST 23, 2026", "ALL AGES"]
  defp date_line_parts(event) do
    event
    |> description_lines()
    |> List.first()
    |> Kernel.||("")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end

  # The description is html, ie. "AUGUST 23, 2026 | ALL AGES<br>6:00PM".  Split
  # on the line breaks before stripping the tags as the text of a parsed
  # fragment collapses them into whitespace.
  defp description_lines(event) do
    (event["description"] || "")
    |> String.split(~r/<br\s*\/?>/i)
    |> Enum.map(fn line ->
      line
      |> Meeseeks.parse()
      |> Selectors.match_one(css("body"))
      |> Selectors.text()
      |> String.trim()
    end)
    |> Enum.reject(&(&1 == ""))
  end
end
