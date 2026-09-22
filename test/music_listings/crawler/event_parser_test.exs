defmodule MusicListings.Crawler.EventParserTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Crawler.EventParser
  alias MusicListings.Crawler.Payload
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HistoryParser
  alias MusicListingsSchema.Venue

  # Parse-error and ignored-event paths log expected warnings/errors. Capture
  # them so they only surface when a test actually fails.
  @moduletag :capture_log

  defmodule TestParserPerDate do
    @moduledoc false
    @behaviour MusicListings.Parsing.VenueParser

    @impl true
    def source_url, do: "https://example.com"
    @impl true
    def retrieve_events_fun, do: fn _e -> {:error, :not_used} end
    @impl true
    def events(_body), do: []
    @impl true
    def next_page_url(_body, _current_url), do: nil
    @impl true
    def event_id(_event), do: "multi_date_event"
    @impl true
    def ignored_event_id(_event), do: "multi_date_event"
    @impl true
    def event_title(_event), do: "Multi-Date Show"
    @impl true
    def performers(_event), do: %Performers{headliner: "Multi-Date Show", openers: []}
    @impl true
    def event_date(_event), do: ~D[2026-05-25]
    @impl true
    def additional_dates(_event), do: [~D[2026-05-26]]
    @impl true
    def event_time(_event), do: ~T[20:00:00]
    @impl true
    def price(_event), do: Price.unknown()
    @impl true
    def age_restriction(_event), do: :unknown
    @impl true
    def ticket_url(_event), do: "https://example.com/tickets/fallback"
    @impl true
    def ticket_url(_event, ~D[2026-05-25]), do: "https://example.com/tickets/may-25"
    def ticket_url(_event, ~D[2026-05-26]), do: "https://example.com/tickets/may-26"
    @impl true
    def details_url(_event), do: "https://example.com/show"
  end

  defmodule TestParserSingleArity do
    @moduledoc false
    @behaviour MusicListings.Parsing.VenueParser

    @impl true
    def source_url, do: "https://example.com"
    @impl true
    def retrieve_events_fun, do: fn _e -> {:error, :not_used} end
    @impl true
    def events(_body), do: []
    @impl true
    def next_page_url(_body, _current_url), do: nil
    @impl true
    def event_id(_event), do: "single_arity_event"
    @impl true
    def ignored_event_id(_event), do: "single_arity_event"
    @impl true
    def event_title(_event), do: "Single Arity Show"
    @impl true
    def performers(_event), do: %Performers{headliner: "Single Arity Show", openers: []}
    @impl true
    def event_date(_event), do: ~D[2026-05-25]
    @impl true
    def additional_dates(_event), do: [~D[2026-05-26]]
    @impl true
    def event_time(_event), do: ~T[20:00:00]
    @impl true
    def price(_event), do: Price.unknown()
    @impl true
    def age_restriction(_event), do: :unknown
    @impl true
    def ticket_url(_event), do: "https://example.com/tickets/only-one"
    @impl true
    def details_url(_event), do: "https://example.com/show"
  end

  # The raw event is the title, so each test can supply its own
  defmodule TestParserTitle do
    @moduledoc false
    @behaviour MusicListings.Parsing.VenueParser

    @impl true
    def source_url, do: "https://example.com"
    @impl true
    def retrieve_events_fun, do: fn _e -> {:error, :not_used} end
    @impl true
    def events(_body), do: []
    @impl true
    def next_page_url(_body, _current_url), do: nil
    @impl true
    def event_id(title), do: title
    @impl true
    def ignored_event_id(title), do: title
    @impl true
    def event_title(title), do: title
    @impl true
    def performers(title), do: %Performers{headliner: title, openers: []}
    @impl true
    def event_date(_title), do: ~D[2026-05-25]
    @impl true
    def additional_dates("Closed " <> _rest), do: [~D[2026-05-26]]
    def additional_dates(_title), do: []
    @impl true
    def event_time(_title), do: nil
    @impl true
    def price(_title), do: Price.unknown()
    @impl true
    def age_restriction(_title), do: :unknown
    @impl true
    def ticket_url(_title), do: nil
    @impl true
    def details_url(_title), do: nil
  end

  describe "parse_events/3" do
    setup do
      payloads = load_payloads("test/data/history/single_event.html")
      venue = Repo.get_by!(Venue, name: "History")

      %{payloads: payloads, venue: venue}
    end

    test "on successful parse returns payload populated with parsed event", %{
      payloads: payloads,
      venue: venue
    } do
      [payload] =
        EventParser.parse_events(
          payloads,
          HistoryParser,
          venue,
          insert(:crawl_summary)
        )

      venue_id = venue.id

      assert %Payload{
               status: :ok,
               parsed_event: %MusicListingsSchema.Event{
                 external_id: "lucky_daye_2024_07_31",
                 title: "Lucky Daye",
                 headliner: "Lucky Daye",
                 openers: [],
                 date: ~D[2024-07-31],
                 time: ~T[20:00:00],
                 price_format: :unknown,
                 price_lo: nil,
                 price_hi: nil,
                 age_restriction: :unknown,
                 ticket_url: "https://www.ticketmaster.ca/event/10006099F25B4189",
                 venue_id: ^venue_id
               }
             } = payload
    end

    test "on failed parse returns payload populated with parse error", %{venue: venue} do
      parse_error_payloads = load_payloads("test/data/history/parse_error_event.html")

      [payload] =
        EventParser.parse_events(
          parse_error_payloads,
          HistoryParser,
          venue,
          insert(:crawl_summary)
        )

      assert :parse_error = payload.status
    end

    test "uses per-date ticket_url for multi-date events when parser implements ticket_url/2",
         %{venue: venue} do
      [payload] =
        EventParser.parse_events(
          [Payload.new(nil)],
          TestParserPerDate,
          venue,
          insert(:crawl_summary)
        )

      assert %Payload{status: :ok, parsed_event: events} = payload
      assert is_list(events)
      assert length(events) == 2

      [event_may_25, event_may_26] = Enum.sort_by(events, & &1.date)

      assert event_may_25.date == ~D[2026-05-25]
      assert event_may_25.ticket_url == "https://example.com/tickets/may-25"

      assert event_may_26.date == ~D[2026-05-26]
      assert event_may_26.ticket_url == "https://example.com/tickets/may-26"
    end

    test "falls back to ticket_url/1 for multi-date events when parser only implements ticket_url/1",
         %{venue: venue} do
      [payload] =
        EventParser.parse_events(
          [Payload.new(nil)],
          TestParserSingleArity,
          venue,
          insert(:crawl_summary)
        )

      assert %Payload{status: :ok, parsed_event: events} = payload
      assert length(events) == 2

      Enum.each(events, fn event ->
        assert event.ticket_url == "https://example.com/tickets/only-one"
      end)
    end
  end

  describe "parse_events/3 - excluded titles" do
    setup do
      %{venue: Repo.get_by!(Venue, name: "History")}
    end

    defp statuses_by_title(titles, venue) do
      titles
      |> Enum.map(&Payload.new/1)
      |> EventParser.parse_events(TestParserTitle, venue, insert(:crawl_summary))
      |> Map.new(&{&1.raw_event, &1.status})
    end

    test "ignores closures, private hires and placeholders, whatever the case", %{venue: venue} do
      titles = [
        "Private Event",
        "PRIVATE BOOKING",
        "closed",
        "Closed!",
        "tba",
        "  To Be Announced  "
      ]

      assert titles |> statuses_by_title(venue) |> Map.values() |> Enum.all?(&(&1 == :ignore))
    end

    test "keeps titles that only contain an excluded phrase", %{venue: venue} do
      titles = ["Closed for Renovations Party", "Open Stage - TBA", "Private Event Band"]

      assert titles |> statuses_by_title(venue) |> Map.values() |> Enum.all?(&(&1 == :ok))
    end

    test "ignores every date of a multi-date listing with an excluded title", %{venue: venue} do
      # additional_dates makes "Closed " titles multi-date, but "Closed " itself
      # trims to "closed"
      assert %{"Closed " => :ignore} == statuses_by_title(["Closed "], venue)
    end
  end

  defp load_payloads(source_file) do
    "#{File.cwd!()}/#{source_file}"
    |> Path.expand()
    |> File.read!()
    |> HistoryParser.events()
    |> Enum.map(&Payload.new/1)
  end
end
