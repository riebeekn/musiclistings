defmodule MusicListings.Parsing.VenueParsers.BowlParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BowlParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/bowl/index.html")

    index_html = File.read!(index_file_path)

    events = BowlParser.events(index_html)

    event = Enum.find(events, &(BowlParser.event_title(&1) == "HOWARD JONES"))

    %{index_html: index_html, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.liveatthebowl.com/upcoming-shows" == BowlParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 9 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil ==
               BowlParser.next_page_url(
                 index_html,
                 "https://www.liveatthebowl.com/upcoming-shows"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "howard_jones_2026_08_23" == BowlParser.event_id(event)
    end

    test "returns a unique id for each event", %{events: events} do
      event_ids = Enum.map(events, &BowlParser.event_id/1)

      assert 9 == event_ids |> Enum.uniq() |> Enum.count()
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "howard_jones_2026_08_23" == BowlParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "HOWARD JONES" == BowlParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "HOWARD JONES", openers: []} == BowlParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-08-23] == BowlParser.event_date(event)
    end

    test "returns the first date of a multi day event", %{events: events} do
      event = Enum.find(events, &(BowlParser.event_title(&1) == "FIRST CLASS FEST"))

      assert ~D[2026-08-28] == BowlParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == BowlParser.additional_dates(event)
    end

    test "returns the remaining dates of a multi day event", %{events: events} do
      # ie. "AUGUST 28 & 29, 2026"
      event = Enum.find(events, &(BowlParser.event_title(&1) == "FIRST CLASS FEST"))

      assert [~D[2026-08-29]] == BowlParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the show time from the event's show page", %{event: event} do
      # the upcoming shows page lists 6:00PM for this show, but that is its
      # doors time - the show page states the show starts at 6:30PM
      assert ~T[18:30:00] == BowlParser.event_time(event)
    end

    test "returns the show time when the upcoming shows page lists no time", %{events: events} do
      event = Enum.find(events, &(BowlParser.event_title(&1) == "HEROES: A VIDEO GAME SYMPHONY"))

      assert ~T[20:00:00] == BowlParser.event_time(event)
    end

    test "falls back to the listed time when the show page is unavailable", %{events: events} do
      # this show has no show page fixture - the upcoming shows page lists
      # 3:00PM for it
      event = Enum.find(events, &(BowlParser.event_title(&1) == "THE LION KING IN CONCERT"))

      assert ~T[15:00:00] == BowlParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == BowlParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :all_ages == BowlParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the ticket url from the event's show page", %{event: event} do
      assert "https://www.ticketmaster.ca/event/10006481D41C232F" ==
               BowlParser.ticket_url(event)
    end

    test "returns the ticket url when the show page labels it get tickets", %{events: events} do
      # the show pages label their ticket link either "BUY TICKETS" or
      # "GET TICKETS"
      event = Enum.find(events, &(BowlParser.event_title(&1) == "INTERPOL"))

      assert "https://www.ticketmaster.ca/interpol-toronto-ontario-10-02-2026/event/1000649B81805BD2" ==
               BowlParser.ticket_url(event)
    end

    test "returns nil when the show page is unavailable", %{events: events} do
      event = Enum.find(events, &(BowlParser.event_title(&1) == "THE LION KING IN CONCERT"))

      assert nil == BowlParser.ticket_url(event)
    end

    test "ignores the meet & greet upsell link", %{events: events} do
      # the heroes show page links a meet & greet add on alongside its ticket
      # link - the add on does not include a base ticket
      event = Enum.find(events, &(BowlParser.event_title(&1) == "HEROES: A VIDEO GAME SYMPHONY"))

      assert "https://www.ticketmaster.ca/event/1000637B86D0385C" ==
               BowlParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.liveatthebowl.com/howard-jones" == BowlParser.details_url(event)
    end
  end
end
