defmodule MusicListings.Parsing.VenueParsers.ReservoirLoungeParser do
  @moduledoc """
  Parser for extracing events from https://www.reservoirlounge.com

  The site's schedule page (https://www.reservoirlounge.com/schedule.html)
  renders a single week's lineup client side from a published Google Sheet,
  so we read that sheet's CSV directly.  The sheet looks like:

      Theme,Swing Era,,,
      Week of,2026-09-22,,,
      ,,,,
      Day,Artist,Genre,Time,Image
      Tuesday,Janice Hagan,"Smoky vocals...",9:00 pm,assets/web/janice-hagan.jpg
      ...
      Sunday,Xavier Solis,"A blend of pop...",8:30 pm,assets/web/xavier-solis.jpg

  "Week of" is the Tuesday that starts the week, each night's date is worked
  out from its day name.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias NimbleCSV.RFC4180, as: CSV

  @base_url "https://www.reservoirlounge.com"

  # The "Lineup" tab of the sheet, linked from js/site-config.js on the site
  @lineup_csv_url "https://docs.google.com/spreadsheets/d/e/2PACX-1vTl2Egl9fk6KXx2FEngyFD-eClJ8WgPCzoOTrW9j6x5KVF9-zdpvJB_CVPHf7KBzuaVt303pzwuh7ki/pub?gid=206764270&single=true&output=csv"

  @days ["tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

  @impl true
  def source_url, do: @lineup_csv_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    rows = decode_rows(body)

    case week_of(rows) do
      nil ->
        []

      start_tuesday ->
        rows
        |> Enum.map(&night(&1, start_tuesday))
        |> Enum.reject(&is_nil/1)
    end
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_venue_and_date("reservoir_lounge", event_date(event))
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event["band"]

  @impl true
  def performers(event), do: Performers.new([event_title(event)])

  @impl true
  def event_date(event), do: event["date"]

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: ParseHelpers.time_from_time_string(event["time"])

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: "#{@base_url}/contact.html#reserve"

  @impl true
  def details_url(_event), do: "#{@base_url}/schedule.html"

  # Req decodes a text/csv response into rows itself, but fixtures are raw text
  defp decode_rows(body) when is_binary(body), do: CSV.parse_string(body, skip_headers: false)
  defp decode_rows(rows) when is_list(rows), do: rows

  # The site hides every date when "Week of" isn't a Tuesday, as the nights
  # would otherwise be labelled with the wrong dates - so skip the week too
  defp week_of(rows) do
    with [_key, value | _rest] <- Enum.find(rows, &(row_key(&1) == "week of")),
         {:ok, date} <- parse_sheet_date(value),
         2 <- Date.day_of_week(date) do
      date
    else
      _no_valid_week -> nil
    end
  end

  defp night([_day, band | rest] = row, start_tuesday) do
    offset = Enum.find_index(@days, &(&1 == row_key(row)))
    band = String.trim(band)

    if offset && band != "" do
      %{
        "band" => band,
        "time" => rest |> Enum.at(1, "") |> String.trim(),
        "date" => Date.add(start_tuesday, offset)
      }
    end
  end

  defp night(_row, _start_tuesday), do: nil

  defp row_key([key | _rest]), do: key |> String.trim() |> String.downcase()
  defp row_key(_row), do: nil

  # Sheets exports the date however the cell is formatted
  defp parse_sheet_date(value) do
    value = String.trim(value)

    cond do
      match = Regex.run(~r/^(\d{4})-(\d{1,2})-(\d{1,2})$/, value) ->
        [_match, year, month, day] = match
        new_date(year, month, day)

      match = Regex.run(~r/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/, value) ->
        [_match, month, day, year] = match
        new_date(year, month, day)

      true ->
        {:error, :invalid_date}
    end
  end

  defp new_date(year, month, day) do
    [year, month, day]
    |> Enum.map(&String.to_integer/1)
    |> then(fn [year, month, day] -> Date.new(year, month, day) end)
  end
end
