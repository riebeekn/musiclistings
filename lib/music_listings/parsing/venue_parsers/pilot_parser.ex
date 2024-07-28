defmodule MusicListings.Parsing.VenueParsers.PilotParser do
  @moduledoc """
  Parser for extracing events from https://thepilot.ca/
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @impl true
  def source_url, do: "https://www.thepilot.ca/happening-at-the-pilot"

  @impl true
  def example_data_file_location, do: "test/data/pilot/index.html"

  @impl true
  def events(body) do
    Selectors.all_matches(
      body,
      css("div#scvr-section-013c83e7-396f-4090-a781-83f7097a960c p.fr-tag")
    )
  end

  @impl true
  def next_page_url(_body) do
    nil
  end

  @impl true
  def event_id(event) do
    # TODO: common
    title_slug = event |> event_title() |> String.replace(" ", "")
    "#{title_slug}-#{event_date(event)}"
  end

  @impl true
  def event_title(event) do
    event
    |> Selectors.text(css(".fr-tag strong, .fr-tag b"))
    |> String.replace(".", "")
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [full_date_string | _rest] =
      event
      |> Selectors.text(css(".fr-tag"))
      |> String.split("-")

    [_day_of_week, month_string, day_string] = String.split(full_date_string)

    # TODO: common
    day =
      day_string
      |> String.trim()
      |> String.replace("st", "")
      |> String.replace("nd", "")
      |> String.replace("rd", "")
      |> String.replace("th", "")
      |> String.replace(",", "")
      |> String.to_integer()

    month = ParseHelpers.convert_month_string_to_number(month_string)

    # TODO: common
    today = Date.utc_today()
    candidate_date = Date.new!(today.year, month, day)
    maybe_increment_year(candidate_date, today)
  end

  defp maybe_increment_year(candidate_date, today) do
    # There is no year provided... so subtract a few days from today
    # then compare the dates if candidate show date < today increment
    # the year...
    # TODO: revisit this, is there some better way of trying to determine
    # the year of the event?
    fifteen_days_ago = Date.add(today, -15)

    if Date.before?(candidate_date, fifteen_days_ago) do
      Date.new!(candidate_date.year + 1, candidate_date.month, candidate_date.day)
    else
      candidate_date
    end
  end

  @impl true
  def event_time(_event) do
    nil
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
  def ticket_url(_event) do
    nil
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
