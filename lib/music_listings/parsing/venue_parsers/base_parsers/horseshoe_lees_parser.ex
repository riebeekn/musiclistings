defmodule MusicListings.Parsing.VenueParsers.BaseParsers.HorseshoeLeesParser do
  @moduledoc """
  Base parser for the Horseshoe Tavern and Lee's Palace, which share a Webflow
  listing template
  """
  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  # The template moved the ticket link in 2026: it used to be the `.blb` button
  # itself and is now an empty overlay anchor at the top of the card, leaving
  # `.blb` a plain div.  Selectors.url/2 reads an href off whatever it matches,
  # so aiming at that div returns nil rather than failing - which is how the
  # Horseshoe went months with no ticket links before anyone noticed.  Both
  # shapes are handled, newest first.
  #
  # A co-promoted show carries a second overlay anchor for the promoter's own
  # vendor; the venue's link is always the first of the two.
  @ticket_link_selector "a.link-standard[href]"
  @legacy_ticket_link_selector "a.blb[href]"

  # The same redesign turned the poster link into a div and dropped per event
  # pages, so a venue on the current template has nothing to link to.
  @details_link_selector "a.schedule-speaker[href]"

  def source_url(base_url), do: "#{base_url}/events"

  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  def events(body) do
    Selectors.all_matches(body, css(".schedule-event"))
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
  end

  def event_title(event) do
    Selectors.text(event, css(".schedule-speaker-name"))
  end

  def performers(event) do
    event
    |> Selectors.all_matches(css(".schedule-speaker-name"))
    |> Selectors.text()
    |> Performers.new()
  end

  # ie. "Saturday, August 22, 2026"
  def event_date(event) do
    full_date_string = Selectors.text(event, css(".schedule-event-time"))

    [_day_of_week, day_month_string, year_string] = String.split(full_date_string, ", ")
    [month_string, day_string] = String.split(day_month_string)

    {:ok, date} =
      ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)

    date
  end

  def additional_dates(_event) do
    []
  end

  # The door time is one of the sibling meta divs, and the only one written as a
  # time.  A venue that doesn't publish one simply has no such div.
  def event_time(event) do
    case event
         |> event_meta()
         |> Enum.find(fn element -> String.contains?(element, "pm") end)
         |> ParseHelpers.build_time_from_time_string() do
      {:ok, time} -> time
      {:error, _reason} -> nil
    end
  end

  def price(event) do
    event
    |> event_meta()
    |> Enum.find(fn element -> String.contains?(element, "$") end)
    |> Price.new()
  end

  def age_restriction(event) do
    event
    |> Selectors.text(css(".non"))
    |> ParseHelpers.age_restriction_string_to_enum()
  end

  def ticket_url(event) do
    Selectors.url(event, css(@ticket_link_selector)) ||
      Selectors.url(event, css(@legacy_ticket_link_selector))
  end

  def details_url(event, base_url) do
    event
    |> Selectors.url(css(@details_link_selector))
    |> case do
      nil -> nil
      "http" <> _rest = url -> url
      path -> base_url <> path
    end
  end

  defp event_meta(event) do
    event
    |> Selectors.all_matches(css(".schedule-event-time"))
    |> Selectors.text()
  end
end
