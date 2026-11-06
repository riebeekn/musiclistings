defmodule MusicListings.Parsing.VenueParsers.HemingwaysParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HemingwaysParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/hemingways/index.html")
    index_html = File.read!(index_file_path)

    events = HemingwaysParser.events(index_html)
    event = List.first(events)

    %{index_html: index_html, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://hemingways.to/events" == HemingwaysParser.source_url()
    end
  end

  describe "events/1" do
    test "returns only the live music events", %{events: events} do
      assert 11 == Enum.count(events)

      assert [] ==
               events
               |> Enum.map(&HemingwaysParser.event_title/1)
               |> Enum.filter(&(&1 =~ ~r/trivia|nations championship|thanksgiving/i))
    end

    test "has a unique id for each event", %{events: events} do
      ids = Enum.map(events, &HemingwaysParser.event_id/1)

      assert ids == Enum.uniq(ids)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == HemingwaysParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "23867" == HemingwaysParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "23867" == HemingwaysParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns the title without the live music prefix", %{event: event} do
      assert "Bailey Jordan-Neil" == HemingwaysParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Bailey Jordan-Neil",
               openers: []
             } == HemingwaysParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-11-06] == HemingwaysParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HemingwaysParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == HemingwaysParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == HemingwaysParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HemingwaysParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == HemingwaysParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url without the empty query string", %{event: event} do
      assert "https://hemingways.to/events/23867/live-music-colin-jennison-copy-9" ==
               HemingwaysParser.details_url(event)
    end
  end
end
