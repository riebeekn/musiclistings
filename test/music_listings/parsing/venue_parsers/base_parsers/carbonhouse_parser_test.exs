defmodule MusicListings.Parsing.VenueParsers.BaseParsers.CarbonhouseParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BaseParsers.CarbonhouseParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/carbonhouse/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/carbonhouse/single_event.html")

    no_events_file_path = Path.expand("#{File.cwd!()}/test/data/carbonhouse/no_events.html")

    index_html = File.read!(index_file_path)
    no_events_html = File.read!(no_events_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> CarbonhouseParser.events()
      |> List.first()

    %{index_html: index_html, no_events_html: no_events_html, event: event}
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = CarbonhouseParser.events(index_html)

      assert 6 = Enum.count(events)
    end
  end

  describe "next_page_url_by_offset/2" do
    test "returns the next page url advanced by the page's event count", %{
      index_html: index_html
    } do
      assert "https://www.historytoronto.com/events/events_ajax/6" ==
               CarbonhouseParser.next_page_url_by_offset(
                 index_html,
                 "https://www.historytoronto.com/events/events_ajax/0"
               )
    end

    test "returns nil when the page has no events", %{no_events_html: no_events_html} do
      assert nil ==
               CarbonhouseParser.next_page_url_by_offset(
                 no_events_html,
                 "https://www.historytoronto.com/events/events_ajax/6"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "lucky_daye_2024_07_31" == CarbonhouseParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "lucky_daye_2024_07_31" == CarbonhouseParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Lucky Daye" == CarbonhouseParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Lucky Daye",
               openers: []
             } == CarbonhouseParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-31] == CarbonhouseParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CarbonhouseParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == CarbonhouseParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               CarbonhouseParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CarbonhouseParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/event/10006099F25B4189" ==
               CarbonhouseParser.ticket_url(event)
    end

    # A run of shows sells each night separately, so the listing renders its
    # "Buy Tickets" as an unclickable span
    test "returns nil when the listing links no tickets" do
      assert nil == CarbonhouseParser.ticket_url(multi_date_event())
    end
  end

  describe "ticket_url/2" do
    test "returns the listed url without reading the event page", %{event: event} do
      assert "https://www.ticketmaster.ca/event/10006099F25B4189" ==
               CarbonhouseParser.ticket_url(event, ~D[2024-07-19])
    end

    test "returns the link for the night being asked about" do
      event = multi_date_event()

      assert "https://www.ticketmaster.ca/isoxo-toronto-ontario-08-28-2026/event/100064ACE7F975D9" ==
               CarbonhouseParser.ticket_url(event, ~D[2026-08-28])
    end

    # The venue enters the odd vendor link with the scheme left off, which would
    # otherwise resolve against our own domain
    test "adds the missing scheme to a link entered without one" do
      event = multi_date_event()

      assert "https://ticketmaster.ca/isoxo-toronto-ontario-08-29-2026/event/100064ACE7FC75DF" ==
               CarbonhouseParser.ticket_url(event, ~D[2026-08-29])
    end

    test "returns nil for a date the event page doesn't list" do
      assert nil == CarbonhouseParser.ticket_url(multi_date_event(), ~D[2026-08-30])
    end
  end

  defp multi_date_event do
    "#{File.cwd!()}/test/data/carbonhouse/single_event_multi_date.html"
    |> Path.expand()
    |> File.read!()
    |> CarbonhouseParser.events()
    |> List.first()
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.historytoronto.com/events/detail/lucky-daye" ==
               CarbonhouseParser.details_url(event)
    end
  end
end
