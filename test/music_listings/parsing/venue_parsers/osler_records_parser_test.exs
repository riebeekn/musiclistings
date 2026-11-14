defmodule MusicListings.Parsing.VenueParsers.OslerRecordsParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.OslerRecordsParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/osler_records/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/osler_records/single_event.json")

    index_body = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> OslerRecordsParser.events()
      |> List.first()

    %{index_body: index_body, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://partners-endpoint.dice.fm/api/v2/events?page%5Bsize%5D=100&types=linkout%2Cevent&filter%5Bvenues%5D%5B%5D=Osler+Records&filter%5Bflags%5D%5B%5D=going_ahead&filter%5Bflags%5D%5B%5D=rescheduled" ==
               OslerRecordsParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_body: index_body} do
      events = OslerRecordsParser.events(index_body)
      assert 4 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_body: index_body} do
      assert nil ==
               OslerRecordsParser.next_page_url(
                 index_body,
                 "https://partners-endpoint.dice.fm/api/v2/events"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "osler_records_6a6cc3ba6a0b2b0001d245a1" == OslerRecordsParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "osler_records_6a6cc3ba6a0b2b0001d245a1" ==
               OslerRecordsParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Weird Nightmare \"Hoopla\" Record Release Shows" ==
               OslerRecordsParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Weird Nightmare",
               openers: ["Dusted", "Jo Passed", "Ancient Greece"]
             } == OslerRecordsParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-18] == OslerRecordsParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == OslerRecordsParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == OslerRecordsParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :fixed, lo: Decimal.new("17.70"), hi: Decimal.new("17.70")} ==
               OslerRecordsParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == OslerRecordsParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://link.dice.fm/V5cc77c663d0" == OslerRecordsParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://link.dice.fm/V5cc77c663d0" == OslerRecordsParser.details_url(event)
    end
  end
end
