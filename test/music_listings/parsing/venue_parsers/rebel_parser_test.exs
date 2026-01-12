defmodule MusicListings.Parsing.VenueParsers.RebelParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RebelParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rebel/index.html")
    single_event_file_path = Path.expand("#{File.cwd!()}/test/data/rebel/single_event.html")

    index_html = File.read!(index_file_path)
    event = File.read!(single_event_file_path)

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://rebeltoronto.com/events/" == RebelParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RebelParser.events(index_html)

      assert 20 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RebelParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      [event] = RebelParser.events(event)
      assert "7487" == RebelParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      [event] = RebelParser.events(event)
      assert "7487" == RebelParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      [event] = RebelParser.events(event)
      assert "SUBTRONICS" == RebelParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      [event] = RebelParser.events(event)

      assert %Performers{
               headliner: "SUBTRONICS",
               openers: []
             } == RebelParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      [event] = RebelParser.events(event)
      # Mock date is 2024-08-01, so January 23 is calculated as next year
      assert ~D[2025-01-23] == RebelParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      [event] = RebelParser.events(event)
      assert [] == RebelParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      [event] = RebelParser.events(event)
      assert nil == RebelParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      [event] = RebelParser.events(event)

      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               RebelParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      [event] = RebelParser.events(event)
      assert :nineteen_plus == RebelParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      [event] = RebelParser.events(event)

      assert "https://www.ticketweb.ca/event/subtronics-fibonacci-tour-rebel-tickets/14610773?pl=ink" ==
               RebelParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      [event] = RebelParser.events(event)
      assert "https://rebeltoronto.com/events/" == RebelParser.details_url(event)
    end
  end
end
