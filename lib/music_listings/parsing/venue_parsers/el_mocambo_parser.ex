defmodule MusicListings.Parsing.VenueParsers.ElMocamboParser do
  @moduledoc """
  Parser for extracing events from https://elmocambo.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  # An event's ticket link is in one of two places, never both: the calendar
  # renders The Events Calendar's Website field as a bare icon carrying no text,
  # and events that leave that field empty instead label a link "GET TICKETS
  # HERE!" in the description on their own page.  Roughly two thirds use the
  # first, which costs nothing to read, so the page is only fetched for the rest.
  @website_icon_selector ".bdt-address-website-icon a"
  @description_selector ".tribe-events-single-event-description"

  # The description also carries unrelated links (a trailer, a charity the show
  # supports), so the ticket link is found by its label rather than by position.
  # Scoping to the description matters on its own: the page's "add to Google
  # Calendar" href embeds the url encoded ticket link, and would otherwise match.
  @ticket_link_text_regex ~r/\btickets?\b/i

  @impl true
  def source_url, do: "https://elmocambo.com/events-new/"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> Selectors.all_matches(css(".bdt-event-item"))
  end

  @impl true
  def next_page_url(_body, _current_url) do
    nil
  end

  @impl true
  def event_id(event) do
    date = event_date(event)
    time = event_time(event)

    ParseHelpers.build_id_from_venue_and_datetime("el_mocambo", date, time)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

  @impl true
  def event_title(event) do
    Selectors.text(event, css(".bdt-event-title-wrap a"))
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    %{"year" => year_string, "month" => month_string, "day" => day_string, "time" => _time_string} =
      parse_out_full_date_time_string(event)

    {:ok, date} =
      if year_string == "" do
        ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
      else
        ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
      end

    date
  end

  defp parse_out_full_date_time_string(event) do
    full_date_and_time_string =
      event
      |> Selectors.match_one(css(".bdt-event-date a"))
      |> Selectors.attr("title")

    regex =
      ~r/Start Date:(?<month>\w+)\s(?<day>\d{1,2})(,?\s(?<year>\d{4}))?\s@\s(?<time>[\d:]+\s[ap]m)/

    Regex.named_captures(regex, full_date_and_time_string)
  end

  @impl true
  def additional_dates(_event) do
    []
  end

  @impl true
  def event_time(event) do
    %{
      "year" => _year_string,
      "month" => _month_string,
      "day" => _day_string,
      "time" => time_string
    } =
      parse_out_full_date_time_string(event)

    case ParseHelpers.build_time_from_time_string(time_string) do
      {:ok, time} -> time
      {:error, _reason} -> nil
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
    event
    |> Selectors.url(css(@website_icon_selector))
    |> case do
      website when is_binary(website) and website != "" -> website
      _no_website -> ticket_url_from_details_page(event)
    end
    |> ParseHelpers.sanitize_ticket_url()
  end

  defp ticket_url_from_details_page(event) do
    with details_url when is_binary(details_url) and details_url != "" <-
           details_url(event),
         {:ok, %HttpClient.Response{status: 200, body: body}} <-
           HttpClient.get(details_url, [], max_retries: 1) do
      body
      |> Selectors.match_one(css(@description_selector))
      |> extract_ticket_link()
    else
      _no_ticket_url -> nil
    end
  end

  defp extract_ticket_link(nil), do: nil

  defp extract_ticket_link(description) do
    description
    |> Selectors.all_matches(css("a[href]"))
    |> Enum.find(&Regex.match?(@ticket_link_text_regex, Selectors.text(&1)))
    |> case do
      nil -> nil
      link -> Selectors.attr(link, "href")
    end
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".bdt-event-title-wrap a"))
  end
end
