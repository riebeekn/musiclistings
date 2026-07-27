defmodule MusicListings.Parsing.VenueParsers.ContxtByTraneParser do
  @moduledoc """
  Parser for extracting events from https://contxtbytrane.com/

  The site has no listings page of its own - everything lives in the venue's
  public "EVENTS IN CONTXT" Google Calendar, which we read through the Google
  Calendar API.

  Two things about that calendar shape the parsing:

    * every entry is an all-day event, so the start time only exists as a
      prefix on the title ("7pm Afro Brasilica", "1-4pm Listening Room")
    * it doubles as the venue's ops calendar, so it also carries dining hours,
      private bookings, brunches, film nights and workshops that we filter out
  """
  @behaviour MusicListings.Parsing.VenueParser

  alias MusicListings.HttpClient
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListingsUtilities.DateHelpers

  @calendar_id "027559b208d0dc7e88f4b87e13bd762b0186c7a96b5521284a8786c0ec36d49c%40group.calendar.google.com"

  # Google's own public browser key, as used by calendar.google.com itself.  The
  # API refuses unregistered callers (403) even for a public calendar, so some
  # key has to be supplied.
  @api_key "AIzaSyDOtGM5jr8bNp1utVpG2_gSRH03RNGBkI8"

  @website "https://contxtbytrane.com/"

  @ticket_hosts [
    "tickets.contxtbytrane.com",
    "square.link",
    "checkout.square.site",
    "buytickets.at",
    "eventbrite."
  ]

  # Calendar entries that are venue operations rather than shows.
  @non_event_terms [
    "dining",
    "private event",
    "film night",
    "workshop",
    "masterclass",
    "craft social",
    "make & meet",
    "public reading"
  ]

  # Meals are only listed when the title also bills someone playing - "Brunch,
  # Market and Music in CONTXT" is a listing, the standing "Brunch in CONTXT" is
  # not.
  @meal_terms ["brunch", "lunch", "dinner"]
  @performance_terms [
    "with",
    "feat",
    "music",
    "concert",
    "band",
    "trio",
    "quartet",
    "quintet",
    "septet",
    "dj",
    "live"
  ]

  # Leading start time: "7pm", "7:30pm", "7pm - ", "1-4pm", "11am-7pm".  The
  # meridiem is taken from the end of a range when the start of it doesn't carry
  # one.
  @time_prefix_regex ~r/^\s*(?<hour>\d{1,2})(?::(?<minute>\d{2}))?\s*(?<meridiem>am|pm)?\s*(?:[-–—]\s*\d{1,2}(?::\d{2})?\s*(?<end_meridiem>am|pm))?\s*[-–—:]?\s*/i

  @impl true
  def source_url do
    "https://www.googleapis.com/calendar/v3/calendars/#{@calendar_id}/events" <>
      "?key=#{@api_key}" <>
      "&singleEvents=true" <>
      "&orderBy=startTime" <>
      "&maxResults=250" <>
      "&timeZone=America/Toronto" <>
      "&timeMin=#{DateHelpers.today_eastern()}T00:00:00Z"
  end

  @impl true
  def retrieve_events_fun do
    fn url -> HttpClient.get(url) end
  end

  @impl true
  def events(body) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("items", [])
    |> Enum.filter(&listable?/1)
  end

  @impl true
  def next_page_url(body, current_url) do
    body
    |> ParseHelpers.maybe_decode!()
    |> Map.get("nextPageToken")
    |> put_page_token(current_url)
  end

  @impl true
  def event_id(event) do
    # `singleEvents=true` expands recurrences, so each instance arrives with its
    # own stable id ("<series id>_20260719").
    event["id"]
  end

  @impl true
  def ignored_event_id(event), do: event_id(event)

  @impl true
  def event_title(event) do
    {_time_string, title} =
      event
      |> raw_title()
      |> split_time_prefix()

    title
    |> ParseHelpers.fix_encoding()
    |> String.trim()
  end

  @impl true
  def performers(event) do
    [event_title(event)]
    |> Performers.new()
  end

  @impl true
  def event_date(event) do
    case event["start"] do
      %{"date" => date} ->
        Date.from_iso8601!(date)

      %{"dateTime" => datetime_string} ->
        {:ok, datetime, _offset} = DateTime.from_iso8601(datetime_string)
        DateHelpers.to_eastern_date(datetime)
    end
  end

  @impl true
  def additional_dates(_event), do: []

  @impl true
  def event_time(event) do
    {time_string, _title} =
      event
      |> raw_title()
      |> split_time_prefix()

    ParseHelpers.time_from_time_string(time_string)
  end

  @impl true
  def price(event) do
    text = String.downcase("#{raw_title(event)} #{event["description"]}")

    cond do
      String.contains?(text, "pwyc") -> Price.new("pwyc")
      String.contains?(text, "free event") -> Price.new("free")
      true -> Price.unknown()
    end
  end

  @impl true
  def age_restriction(_event), do: :unknown

  @impl true
  def ticket_url(event) do
    event["description"]
    |> links()
    |> Enum.find(&ticket_link?/1)
    |> case do
      {url, _text} -> ParseHelpers.sanitize_ticket_url(url)
      nil -> nil
    end
  end

  @impl true
  def details_url(event) do
    ticket_url(event) || @website
  end

  # ===========================================================================
  # Filtering
  # ===========================================================================
  defp listable?(event) do
    confirmed?(event) and on_site?(event) and gig?(event)
  end

  defp confirmed?(event), do: event["status"] in [nil, "confirmed"]

  # Shows CONTXT presents at other venues ("... at 918 Bathurst", "... at
  # Redwood Theatre") belong to those venues, several of which we crawl
  # ourselves.
  defp on_site?(event) do
    !Regex.match?(~r/\bat\s+(?!contxt)/i, raw_title(event)) and
      on_site_location?(event["location"])
  end

  defp on_site_location?(nil), do: true
  defp on_site_location?(location), do: Regex.match?(~r/contxt|lansdowne/i, location)

  defp gig?(event) do
    title = event |> event_title() |> String.downcase()

    !Enum.any?(@non_event_terms, &String.contains?(title, &1)) and
      (!Enum.any?(@meal_terms, &String.contains?(title, &1)) or
         Enum.any?(@performance_terms, &String.contains?(title, &1)))
  end

  # ===========================================================================
  # Title / time parsing
  # ===========================================================================
  defp raw_title(event) do
    # Titles pasted in from elsewhere sometimes carry non-breaking spaces, which
    # the time-prefix regex's \s does not match.
    (event["summary"] || "")
    |> String.replace("\u00A0", " ")
  end

  # Splits a leading start time off the title.  When no meridiem is present the
  # leading number can't be trusted to be a time ("5 WEEKS FOR MILES"), so the
  # title is left untouched and the event gets no time.
  defp split_time_prefix(title) do
    case Regex.named_captures(@time_prefix_regex, title) do
      nil ->
        {nil, title}

      captures ->
        meridiem =
          if captures["meridiem"] == "", do: captures["end_meridiem"], else: captures["meridiem"]

        if meridiem == "" do
          {nil, title}
        else
          {time_string(captures["hour"], captures["minute"], meridiem),
           Regex.replace(@time_prefix_regex, title, "", global: false)}
        end
    end
  end

  defp time_string(hour, "", meridiem), do: "#{hour}#{meridiem}"
  defp time_string(hour, minute, meridiem), do: "#{hour}:#{minute}#{meridiem}"

  # ===========================================================================
  # Links
  #
  # Links live in the event's HTML description, wrapped in Google Calendar's
  # redirector: href="https://www.google.com/url?q=<real url>&sa=D&ust=..."
  # Descriptions also carry artist sites, Instagram and mailto links, so a link
  # only counts as a ticket link when its text says so ("Get Tickets", "RSVP
  # here") or it points at a ticket vendor.
  # ===========================================================================
  defp links(nil), do: []

  defp links(description) do
    ~r/<a[^>]*href="([^"]+)"[^>]*>(.*?)<\/a>/s
    |> Regex.scan(description)
    |> Enum.map(fn [_match, href, text] ->
      {href |> ParseHelpers.fix_encoding() |> unwrap_google_redirect(), strip_tags(text)}
    end)
    |> Enum.filter(fn {url, _text} -> String.starts_with?(url, "http") end)
  end

  defp ticket_link?({url, text}) do
    Regex.match?(~r/ticket|rsvp/i, text) or
      Enum.any?(@ticket_hosts, &String.contains?(url, &1))
  end

  defp strip_tags(text) do
    text
    |> String.replace(~r/<[^>]*>/, "")
    |> ParseHelpers.fix_encoding()
  end

  defp unwrap_google_redirect(url) do
    uri = URI.parse(url)

    if uri.host in ["www.google.com", "google.com"] and uri.path == "/url" do
      (uri.query || "")
      |> URI.decode_query()
      |> Map.get("q", url)
    else
      url
    end
  end

  # ===========================================================================
  # Paging
  # ===========================================================================
  defp put_page_token(nil, _current_url), do: nil
  defp put_page_token(_token, nil), do: nil

  defp put_page_token(token, current_url) do
    uri = URI.parse(current_url)

    query =
      (uri.query || "")
      |> URI.decode_query()
      |> Map.put("pageToken", token)
      |> URI.encode_query()

    URI.to_string(%{uri | query: query})
  end
end
