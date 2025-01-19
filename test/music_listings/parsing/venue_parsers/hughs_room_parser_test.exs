defmodule MusicListings.Parsing.VenueParsers.HughsRoomParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HughsRoomParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/hughs_room/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/hughs_room/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> HughsRoomParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://hughsroomlive.com/on-stage/?page_number=1" == HughsRoomParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = HughsRoomParser.events(index_html)

      assert 8 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url when there are more pages", %{index_html: index_html} do
      assert "https://hughsroomlive.com/on-stage/?page_number=2" ==
               HughsRoomParser.next_page_url(
                 index_html,
                 "https://hughsroomlive.com/on-stage/?page_number=1"
               )
    end

    test "returns nil when no more pages", %{index_html: index_html} do
      assert nil ==
               HughsRoomParser.next_page_url(
                 index_html,
                 "https://hughsroomlive.com/on-stage/?page_number=8"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "original-people-original-songs-with-the-north-sound" ==
               HughsRoomParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns event id", %{event: event} do
      assert "original-people-original-songs-with-the-north-sound" ==
               HughsRoomParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Original People Original Songs with The North Sound" ==
               HughsRoomParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Original People Original Songs with The North Sound",
               openers: []
             } == HughsRoomParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-03-26] == HughsRoomParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HughsRoomParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == HughsRoomParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :range, lo: Decimal.new("15.00"), hi: Decimal.new("30.00")} ==
               HughsRoomParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HughsRoomParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.showpass.com/original-people-original-songs-with-the-north-sound" ==
               HughsRoomParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == HughsRoomParser.details_url(event)
    end
  end
end
