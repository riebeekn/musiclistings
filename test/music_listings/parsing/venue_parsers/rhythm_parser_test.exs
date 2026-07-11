defmodule MusicListings.Parsing.VenueParsers.RhythmParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RhythmParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rhythm/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> RhythmParser.events()
      |> Enum.find(&(&1["id"] == "2480884"))

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://ra.co/clubs/248685" == RhythmParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RhythmParser.events(index_html)

      assert 11 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == RhythmParser.next_page_url(index_html, "https://ra.co/clubs/248685")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "rhythm_2480884" == RhythmParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "rhythm_2480884" == RhythmParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Rhythm presents: John Beltran (Placid Angles) with Ficilio" ==
               RhythmParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Rhythm presents: John Beltran (Placid Angles) with Ficilio",
               openers: []
             } == RhythmParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-18] == RhythmParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == RhythmParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00.000] == RhythmParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == RhythmParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == RhythmParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == RhythmParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://ra.co/events/2480884" == RhythmParser.details_url(event)
    end
  end
end
