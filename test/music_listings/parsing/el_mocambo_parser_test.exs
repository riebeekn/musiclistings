defmodule MusicListings.Parsing.ElMocamboParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.ElMocamboParser
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/el_mocambo/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/el_mocambo/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> ElMocamboParser.event_selector()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://elmocambo.com/events-new/" == ElMocamboParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "El Mocambo" == ElMocamboParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = ElMocamboParser.event_selector(index_html)

      assert 15 == Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == ElMocamboParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "HighFlyerReleaseShow-2024-08-23" == ElMocamboParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "High Flyer Release Show" == ElMocamboParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "High Flyer Release Show",
               openers: []
             } == ElMocamboParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-23] == ElMocamboParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == ElMocamboParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               ElMocamboParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == ElMocamboParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketweb.ca/event/high-flyer-release-show-the-starlight-room-at-the-tickets/13766233?pl=elmocambo" ==
               ElMocamboParser.ticket_url(event)
    end
  end
end