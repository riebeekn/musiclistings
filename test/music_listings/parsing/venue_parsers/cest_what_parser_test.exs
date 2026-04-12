defmodule MusicListings.Parsing.VenueParsers.CestWhatParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.CestWhatParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/cest_what/index.html")
    index_html = File.read!(index_file_path)

    events = CestWhatParser.events(index_html)
    event = List.first(events)

    %{index_html: index_html, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://cestwhat.com/event-poster/" == CestWhatParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 7 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == CestWhatParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "cest_what_2025_04_10_21_00_00" == CestWhatParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "cest_what_2025_04_10_21_00_00" == CestWhatParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Honest Liars" == CestWhatParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Honest Liars",
               openers: []
             } == CestWhatParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-04-10] == CestWhatParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CestWhatParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == CestWhatParser.event_time(event)
    end

    test "normalizes start time when am/pm is missing", %{events: events} do
      # APR 11 Hot 5 Jazzmakers | 3-6pm -> 3pm
      afternoon_event = Enum.at(events, 1)
      assert ~T[15:00:00] == CestWhatParser.event_time(afternoon_event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               CestWhatParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CestWhatParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == CestWhatParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://cestwhat.com/event-poster/" ==
               CestWhatParser.details_url(event)
    end
  end
end
