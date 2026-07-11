defmodule MusicListings.Parsing.VenueParsers.WiggleRoomParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.WiggleRoomParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/wiggle_room/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> WiggleRoomParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://wiggleroomtoronto.com/events/" == WiggleRoomParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = WiggleRoomParser.events(index_html)

      assert 13 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://wiggleroomtoronto.com/events/list/page/2/" ==
               WiggleRoomParser.next_page_url(
                 index_html,
                 "https://wiggleroomtoronto.com/events/"
               )
    end

    test "returns nil after grabbing page 4", %{index_html: index_html} do
      assert nil ==
               WiggleRoomParser.next_page_url(
                 index_html,
                 "https://wiggleroomtoronto.com/events/list/page/4/"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "wiggle_room_2026_07_10_22_00_00" == WiggleRoomParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "wiggle_room_2026_07_10_22_00_00" == WiggleRoomParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Dance Division 014 | 4AM LAST CALL" == WiggleRoomParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Dance Division 014 | 4AM LAST CALL",
               openers: []
             } == WiggleRoomParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-10] == WiggleRoomParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == WiggleRoomParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[22:00:00] == WiggleRoomParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               WiggleRoomParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == WiggleRoomParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == WiggleRoomParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://wiggleroomtoronto.com/event/dance-division-014/" ==
               WiggleRoomParser.details_url(event)
    end
  end
end
