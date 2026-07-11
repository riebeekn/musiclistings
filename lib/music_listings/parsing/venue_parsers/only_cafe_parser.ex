defmodule MusicListings.Parsing.VenueParsers.OnlyCafeParser do
  @moduledoc """
  Parser for extracting events from https://www.theonlycafe.com/shows

  The Only Cafe runs a hand-maintained Google Sites page. Events have no
  structured markup - each show is three consecutive `<p>` paragraphs (a date
  line, a performer line, and a time line), e.g. "Thursday July 9th",
  "Jake B.K. Trio", "7-10 P.M". Google Sites also splits text across spans, so
  a date can render as "Fri day July 1 0 th" - we strip spaces before parsing
  the date/time out of it.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @source_url "https://www.theonlycafe.com/shows"

  @months ~w(january february march april may june july august september october november december)

  # Month name immediately followed by the day number, once intra-word spaces
  # have been stripped (e.g. "fridayjuly10th" -> month "july", day "10").
  @date_regex ~r/(january|february|march|april|may|june|july|august|september|october|november|december)(\d{1,2})/

  @impl true
  def source_url, do: @source_url

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    paragraphs =
      body
      |> Selectors.all_matches(css("p.zfr3Q"))
      |> Enum.map(&Meeseeks.text/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    paragraphs
    |> Enum.with_index()
    |> Enum.filter(fn {text, _index} -> date_paragraph?(text) end)
    |> Enum.map(fn {date_text, index} ->
      %{
        "date_text" => date_text,
        "title" => Enum.at(paragraphs, index + 1),
        "time_text" => Enum.at(paragraphs, index + 2)
      }
    end)
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    ParseHelpers.build_id_from_venue_and_datetime(
      "only_cafe",
      event_date(event),
      event_time(event)
    )
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event), do: event["title"]

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    [_match, month_string, day_string] =
      event["date_text"]
      |> squish()
      |> then(&Regex.run(@date_regex, &1))

    {:ok, date} = ParseHelpers.build_date_from_month_day_strings(month_string, day_string)
    date
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event) do
    case event["time_text"] do
      nil ->
        nil

      time_text ->
        squished = squish(time_text)
        meridiem = meridiem(squished)

        start =
          squished
          |> String.split("-")
          |> List.first()
          |> String.replace(~r/[^\d:]/, "")

        case ParseHelpers.build_time_from_time_string("#{start} #{meridiem}") do
          {:ok, time} -> time
          {:error, _reason} -> nil
        end
    end
  end

  @impl true
  def price(_event), do: Price.unknown()

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(_event), do: nil

  @impl true
  def details_url(_event), do: @source_url

  defp date_paragraph?(text) do
    squished = squish(text)
    Enum.any?(@months, &String.contains?(squished, &1)) and Regex.match?(~r/\d{1,2}/, squished)
  end

  defp meridiem(squished) do
    cond do
      String.contains?(squished, "pm") or String.contains?(squished, "p.m") -> "pm"
      String.contains?(squished, "am") or String.contains?(squished, "a.m") -> "am"
      true -> ""
    end
  end

  defp squish(text), do: text |> String.replace(" ", "") |> String.downcase()
end
