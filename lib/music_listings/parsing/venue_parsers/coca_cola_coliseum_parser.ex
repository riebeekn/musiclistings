defmodule MusicListings.Parsing.VenueParsers.CocaColaColiseumParser do
  @moduledoc """
  Parser for extracing events from https://www.coca-colacoliseum.com/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.coca-colacoliseum.com/events"

  @impl true
  def example_data_file_location, do: "test/data/coca_cola_coliseum/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(body, css(".m-venueframework-eventslist__item"))
  end

  @impl true
  def next_page_url(_body) do
    # no next page
    nil
  end

  @impl true
  def event_id(event) do
    title = event_title(event)
    date = event_date(event)

    ParseHelpers.build_id_from_title_and_date(title, date)
  end

  @impl true
  def event_title(event) do
    main_title = Selectors.text(event, css(".m-eventItem__title"))
    secondary_title = Selectors.text(event, css(".m-eventItem__tagline"))

    build_full_title(main_title, secondary_title)
  end

  defp build_full_title(main_title, nil), do: main_title
  defp build_full_title(main_title, secondary_title), do: "#{main_title} #{secondary_title}"

  @impl true
  def performers(event) do
    event
    |> Selectors.all_matches(css(".m-eventItem__title"))
    |> Selectors.text()
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    day_string = Selectors.text(event, css(".m-date__day"))
    month_string = Selectors.text(event, css(".m-date__month"))
    year_string = Selectors.text(event, css(".m-date__year"))

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
  end

  @impl true
  def event_time(event) do
    event
    |> Selectors.text(css(".m-eventItem__start"))
    |> ParseHelpers.time_string_to_time()
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
    Selectors.url(event, css(".tickets"))
  end

  @impl true
  def details_url(event) do
    Selectors.url(event, css(".more"))
  end
end
