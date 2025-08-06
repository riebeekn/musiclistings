defmodule MusicListings.Parsing.VenueParsers.JunctionUndergroundParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.JunctionUndergroundParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/junction_underground/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/junction_underground/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> JunctionUndergroundParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://junctionunderground.ca/events/" == JunctionUndergroundParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = JunctionUndergroundParser.events(index_html)

      assert 8 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://junctionunderground.ca/events/list/page/2/" ==
               JunctionUndergroundParser.next_page_url(
                 index_html,
                 "https://junctionunderground.ca/events/"
               )
    end

    test "after grabbing page 3 it returns page 4", %{index_html: index_html} do
      assert "https://junctionunderground.ca/events/list/page/4/" ==
               JunctionUndergroundParser.next_page_url(
                 index_html,
                 "https://junctionunderground.ca/events/list/page/3/"
               )
    end

    test "returns nil after grabbing page 4", %{index_html: index_html} do
      assert nil ==
               JunctionUndergroundParser.next_page_url(
                 index_html,
                 "https://junctionunderground.ca/events/list/page/4/"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "junction_underground_2025_08_07_19_00_00" ==
               JunctionUndergroundParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "junction_underground_2025_08_07_19_00_00" ==
               JunctionUndergroundParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "MORE NOISE PLEASE!" == JunctionUndergroundParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "MORE NOISE PLEASE!",
               openers: []
             } == JunctionUndergroundParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-08-07] == JunctionUndergroundParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == JunctionUndergroundParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == JunctionUndergroundParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               JunctionUndergroundParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == JunctionUndergroundParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == JunctionUndergroundParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://junctionunderground.ca/event/more-noise-please/" ==
               JunctionUndergroundParser.details_url(event)
    end
  end
end
