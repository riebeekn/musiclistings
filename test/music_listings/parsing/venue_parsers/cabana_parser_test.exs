defmodule MusicListings.Parsing.VenueParsers.CabanaParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.CabanaParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/cabana/index.html")

    index_html = File.read!(index_file_path)

    events = CabanaParser.events(index_html)

    event = Enum.find(events, &(CabanaParser.event_id(&1) == "cabana_2363"))

    %{index_html: index_html, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://cabanatoronto.com/events/" == CabanaParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 22 == Enum.count(events)
    end

    test "does not return duplicate events", %{events: events} do
      # the page renders its first couple of events a second time in a
      # separate elementor loop
      event_ids = Enum.map(events, &CabanaParser.event_id/1)

      assert 22 == event_ids |> Enum.uniq() |> Enum.count()
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil ==
               CabanaParser.next_page_url(index_html, "https://cabanatoronto.com/events/")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "cabana_2363" == CabanaParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "cabana_2363" == CabanaParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "BRANDI CYRUS: DJ SET" == CabanaParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "BRANDI CYRUS: DJ SET", openers: []} ==
               CabanaParser.performers(event)
    end
  end

  describe "event_date/1" do
    # cabana lists dates without a year, so the year is inferred relative to
    # the mocked current date (2024-08-01)
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-22] == CabanaParser.event_date(event)
    end

    test "returns a date for every event", %{events: events} do
      assert [] == Enum.filter(events, &(CabanaParser.event_date(&1) == nil))
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CabanaParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns nil as no times are listed", %{event: event} do
      assert nil == CabanaParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == CabanaParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CabanaParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketweb.ca/event/brandi-cyrus-cabana-toronto-tickets/14222774?pl=Rebel" ==
               CabanaParser.ticket_url(event)
    end

    test "returns nil when the event has no buy tickets button", %{events: events} do
      event = Enum.find(events, &(CabanaParser.event_id(&1) == "cabana_2164"))

      assert nil == CabanaParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns nil as the event cards have no per-event link", %{event: event} do
      assert nil == CabanaParser.details_url(event)
    end
  end
end
