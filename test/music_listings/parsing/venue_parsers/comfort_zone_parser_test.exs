defmodule MusicListings.Parsing.VenueParsers.ComfortZoneParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ComfortZoneParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/comfort_zone/index.json")

    index_json = File.read!(index_file_path)

    event =
      index_json
      |> ComfortZoneParser.events()
      |> Enum.find(&(&1["id"] == "2474787"))

    %{index_json: index_json, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://ra.co/clubs/4665" == ComfortZoneParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_json: index_json} do
      events = ComfortZoneParser.events(index_json)

      assert 5 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == ComfortZoneParser.next_page_url(index_json, "https://ra.co/clubs/4665")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "comfort_zone_2474787" == ComfortZoneParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "comfort_zone_2474787" == ComfortZoneParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "404: ANSBRO" == ComfortZoneParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "404: ANSBRO",
               openers: []
             } == ComfortZoneParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-17] == ComfortZoneParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == ComfortZoneParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[23:59:00.000] == ComfortZoneParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == ComfortZoneParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ComfortZoneParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == ComfortZoneParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://ra.co/events/2474787" == ComfortZoneParser.details_url(event)
    end
  end
end
