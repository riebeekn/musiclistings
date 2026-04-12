defmodule MusicListings.Parsing.VenueParsers.StandardTimeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.StandardTimeParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/standard_time/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/standard_time/single_event.json")

    index_body = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> StandardTimeParser.events()
      |> List.first()

    %{index_body: index_body, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://partners-endpoint.dice.fm/api/v2/events?page%5Bsize%5D=24&types=linkout%2Cevent&filter%5Bvenues%5D%5B%5D=Standard+Time&filter%5Bflags%5D%5B%5D=going_ahead&filter%5Bflags%5D%5B%5D=rescheduled" ==
               StandardTimeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_body: index_body} do
      events = StandardTimeParser.events(index_body)
      assert 7 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_body: index_body} do
      assert nil ==
               StandardTimeParser.next_page_url(
                 index_body,
                 "https://partners-endpoint.dice.fm/api/v2/events"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "standard_time_69bca2edd233680001d499a9" == StandardTimeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "standard_time_69bca2edd233680001d499a9" ==
               StandardTimeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Jump Source - Open to Close" == StandardTimeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Jump Source",
               openers: ["Priori", "Patrick Holland"]
             } == StandardTimeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-04-17] == StandardTimeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == StandardTimeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[22:00:00] == StandardTimeParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :range, lo: Decimal.new("21.27"), hi: Decimal.new("35.83")} ==
               StandardTimeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == StandardTimeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://link.dice.fm/b063c65e33c3" == StandardTimeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://link.dice.fm/b063c65e33c3" == StandardTimeParser.details_url(event)
    end
  end
end
