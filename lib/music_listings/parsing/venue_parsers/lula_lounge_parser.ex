defmodule MusicListings.Parsing.VenueParsers.LulaLoungeParser do
  @moduledoc """
  Parser for extracting events from https://www.lula.ca/calendar

  The Wix page embeds the "Event Viewer" (Ticket Spot) app, which serves the venue's
  Eventbrite events as JSON, i.e.

      [%{"id" => "2002113624747",
         "title" => "Salsa Saturday w Adis Rodriguez  +  DJ Van Gogh + Baila Boogaloo!",
         "url" => "https://www.eventbrite.ca/e/...-tickets-2002113624747",
         "status" => "live",
         "date" => %{"start" => %{"local" => "2026-11-14T20:30:00", ...}, ...},
         "tickets" => [%{"free" => false, "cost" => %{"major_value" => "20.00", ...}, ...}],
         ...}]

  The app's API needs a signed, rotating Wix instance token, so each crawl first fetches
  one from the site's `/_api/v1/access-tokens` (the same approach as `FreeTimesCafeParser`).
  `13628e78-…` is the Event Viewer app's global Wix app id and `comp-me1ou9kk` is the
  widget on the calendar page.
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  @comp_id "comp-me1ou9kk"
  @event_viewer_app_def_id "13628e78-3e5c-8b05-bd36-18fe0e00ada3"

  @tokens_url "https://www.lula.ca/_api/v1/access-tokens"
  @events_base "https://api.geteventviewer.com/api/v1/events"

  @impl true
  def source_url, do: "https://www.lula.ca/calendar"

  @impl true
  def retrieve_events_fun do
    fn _url ->
      with {:ok, instance} <- fetch_instance() do
        instance
        |> events_url()
        |> HttpClient.get(request_headers())
      end
    end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> case do
      events when is_list(events) -> Enum.filter(events, &listed?/1)
      _unexpected_shape -> []
    end
  end

  @impl true
  def next_page_url(_body, _current_url), do: nil

  # Each date of a recurring night is its own Eventbrite event with its own id
  @impl true
  def event_id(event), do: "lula_lounge_#{event["id"]}"

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    event["title"]
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event), do: event |> start_datetime() |> NaiveDateTime.to_date()

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event), do: event |> start_datetime() |> NaiveDateTime.to_time()

  # Events sell several tiers (early bird, general, line by-pass, dinner packages,
  # bottle service...), so the cheapest paid ticket is shown as a "from" price.
  # Free tiers are usually comps or passes, so they only count when nothing is paid.
  @impl true
  def price(event) do
    tickets = event["tickets"] || []

    paid_prices =
      tickets
      |> Enum.reject(&(&1["free"] == true))
      |> Enum.map(&get_in(&1, ["cost", "major_value"]))
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&Decimal.new/1)
      |> Enum.uniq_by(&Decimal.normalize/1)

    cond do
      paid_prices == [] and Enum.any?(tickets, &(&1["free"] == true)) ->
        Price.new("free")

      paid_prices == [] ->
        Price.unknown()

      length(paid_prices) == 1 ->
        paid_prices |> hd() |> Decimal.to_string() |> Price.new()

      true ->
        paid_prices |> Enum.min(Decimal) |> Decimal.to_string() |> Kernel.<>("+") |> Price.new()
    end
  end

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(event), do: ParseHelpers.sanitize_ticket_url(event["url"])

  @impl true
  def details_url(event), do: ticket_url(event)

  # ===========================================================================
  # Fetching
  # ===========================================================================
  defp fetch_instance do
    case HttpClient.get(@tokens_url, request_headers()) do
      {:ok, %Response{status: 200, body: body}} ->
        body
        |> ParseHelpers.maybe_decode!()
        |> get_in(["apps", @event_viewer_app_def_id, "instance"])
        |> case do
          instance when is_binary(instance) and instance != "" -> {:ok, instance}
          _missing -> {:error, :no_instance}
        end

      {:ok, %Response{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, _reason} = error ->
        error
    end
  end

  # Without `brand=wix` the API answers 401 "Unauthorized Session"
  defp events_url(instance) do
    query = URI.encode_query(%{"compId" => @comp_id, "instance" => instance, "brand" => "wix"})
    "#{@events_base}?#{query}"
  end

  defp request_headers do
    [
      {"accept", "application/json, text/plain, */*"},
      {"user-agent",
       "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36"}
    ]
  end

  # ===========================================================================
  # Helpers
  # ===========================================================================
  defp listed?(event) do
    event["status"] == "live" and event["listed"] != false and event["online_event"] != true and
      is_binary(get_in(event, ["date", "start", "local"]))
  end

  # Eventbrite's local start time is Toronto's wall clock time
  defp start_datetime(event) do
    event
    |> get_in(["date", "start", "local"])
    |> NaiveDateTime.from_iso8601!()
  end
end
