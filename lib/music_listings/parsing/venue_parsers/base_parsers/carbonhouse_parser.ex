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
    |> Enum.reject(&is_toronto_sceptres?/1)
  end

  defp is_toronto_sceptres?(event_item) do
    event_item
    |> Selectors.text(css(".title"))
    |> String.contains?("Toronto Sceptres")
  end

  def next_page_url(_body, _current_url) do
    # no next page
    nil
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
    |> Performers.new()
  end

  def event_date(event) do
    day_string = Selectors.text(event, css(".m-date__day"))
    month_string = Selectors.text(event, css(".m-date__month"))
    year_string = Selectors.text(event, css(".m-date__year"))

    ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
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
        ParseHelpers.build_date_from_year_month_day_strings(year_string, month_string, day_string)
      end)
    end
  end

  def event_time(event) do
    event
    |> Selectors.text(css(".start"))
    |> ParseHelpers.build_time_from_time_string()
  end

  def price(_event) do
    Price.unknown()
  end

  def age_restriction(_event) do
    :unknown
  end

  def ticket_url(event) do
    Selectors.url(event, css(".tickets"))
  end

  def details_url(event) do
    Selectors.url(event, css(".more"))
  end
end
