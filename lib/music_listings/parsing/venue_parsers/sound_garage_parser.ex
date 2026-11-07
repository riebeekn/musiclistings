defmodule MusicListings.Parsing.VenueParsers.SoundGarageParser do
  @moduledoc """
  Parser for extracting events from https://www.bloodbrothersbrewing.com/pages/the-sound-garage-165-geary-ave

  The page is edited by hand and has no consistent structure. An event is a heading holding its
  title and date - an `<h1>` or a `<strong>`, with the month spelled out or abbreviated - followed
  by its ticket link.
  """
  @behaviour MusicListings.Parsing.VenueParser

  import Meeseeks.CSS

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.Selectors

  @date_regex ~r/\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\.?\s+(\d{1,2})\b/i

  @impl true
  def source_url,
    do: "https://www.bloodbrothersbrewing.com/pages/the-sound-garage-165-geary-ave"

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> normalize_html()
    |> split_into_chunks()
    |> build_events()
  end

  defp normalize_html(body) do
    body
    |> String.replace(~r/<br\s*\/?>/, "\n")
  end

  defp split_into_chunks(html) do
    ~r/(?=<(?:h1|strong)[\s>])/i
    |> Regex.split(html)
    |> Enum.filter(&Regex.match?(~r/^<(?:h1|strong)[\s>]/i, &1))
  end

  defp build_events(chunks) do
    {events, _buffer} =
      Enum.reduce(chunks, {[], []}, fn chunk, {events, buffer} ->
        heading_text = extract_heading_text(chunk)
        process_chunk(heading_text, chunk, events, buffer)
      end)

    Enum.reverse(events)
  end

  defp process_chunk(heading_text, chunk, events, buffer) do
    case Regex.run(@date_regex, heading_text) do
      [_match, month, day] ->
        event = build_event(heading_text, month, day, chunk, buffer)
        {[event | events], []}

      nil ->
        accumulate_title(heading_text, events, buffer)
    end
  end

  defp build_event(heading_text, month, day, chunk, buffer) do
    title_text = remove_date(heading_text)
    title = buffer |> Enum.reverse() |> Kernel.++([title_text]) |> build_title()

    %{
      "title" => title,
      "month" => month,
      "day" => day,
      "ticket_url" => extract_ticket_url(chunk)
    }
  end

  defp accumulate_title(heading_text, events, buffer) do
    if page_title?(heading_text) do
      {events, buffer}
    else
      {events, [clean_text(heading_text) | buffer]}
    end
  end

  defp extract_heading_text(chunk) do
    chunk
    |> Selectors.match_one(css("h1, strong"))
    |> Selectors.text()
  end

  defp extract_ticket_url(chunk) do
    chunk
    |> Selectors.all_matches(css("a[href]"))
    |> Enum.map(&Selectors.attr(&1, "href"))
    |> Enum.find(&ticket_link?/1)
  end

  defp ticket_link?(url) do
    String.contains?(url, "ticketweb") or
      String.contains?(url, "tixr.com") or
      String.contains?(url, "eventbrite") or
      String.contains?(url, "dice.fm")
  end

  defp remove_date(text) do
    @date_regex
    |> Regex.replace(text, "")
    |> String.replace(~r/[\s\-–—:,|]+$/u, "")
  end

  defp clean_text(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp build_title(parts) do
    parts
    |> Enum.map(&clean_text/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp page_title?(text) do
    text
    |> clean_text()
    |> String.upcase()
    |> String.contains?("SOUND GARAGE")
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  @impl true
  def event_id(event) do
    date = event_date(event)
    ParseHelpers.build_id_from_venue_and_date("sound_garage", date)
  end

  @impl true
  def ignored_event_id(event) do
    event_id(event)
  end

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
    {:ok, date} = ParseHelpers.build_date_from_month_day_strings(event["month"], event["day"])
    date
  end

  @impl true
  def additional_dates(_event) do
    []
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
  def ticket_url(event) do
    event["ticket_url"]
  end

  @impl true
  def details_url(_event) do
    nil
  end
end
