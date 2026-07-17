defmodule MusicListings.Parsing.VenueParsers.TapestryParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.TapestryParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/tapestry/index.json")

    index_json = File.read!(index_file_path)

    event =
      index_json
      |> TapestryParser.events()
      |> Enum.find(&(&1["id"] == "2478710"))

    %{index_json: index_json, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://ra.co/clubs/208391" == TapestryParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_json: index_json} do
      events = TapestryParser.events(index_json)

      assert 1 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == TapestryParser.next_page_url(index_json, "https://ra.co/clubs/208391")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "tapestry_2478710" == TapestryParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "tapestry_2478710" == TapestryParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "FourByFour presents: The Night Shift" == TapestryParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "FourByFour presents: The Night Shift",
               openers: []
             } == TapestryParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-18] == TapestryParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == TapestryParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00.000] == TapestryParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == TapestryParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == TapestryParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == TapestryParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://ra.co/events/2478710" == TapestryParser.details_url(event)
    end
  end
end
