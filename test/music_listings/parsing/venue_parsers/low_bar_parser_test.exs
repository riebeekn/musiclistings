defmodule MusicListings.Parsing.VenueParsers.LowBarParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.LowBarParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/low_bar/index.json")

    index_json = File.read!(index_file_path)

    event =
      index_json
      |> LowBarParser.events()
      |> Enum.find(&(&1["id"] == "d7420b72-68f0-4a32-8881-3e226f18dd37"))

    %{index_json: index_json, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://ma.to/venue/l0w_bar" == LowBarParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_json: index_json} do
      events = LowBarParser.events(index_json)

      assert 3 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == LowBarParser.next_page_url(index_json, "https://ma.to/venue/l0w_bar")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "low_bar_d7420b72-68f0-4a32-8881-3e226f18dd37" == LowBarParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "low_bar_d7420b72-68f0-4a32-8881-3e226f18dd37" ==
               LowBarParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Knight Moves: Disco Chess Club" == LowBarParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Knight Moves: Disco Chess Club",
               openers: []
             } == LowBarParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-29] == LowBarParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == LowBarParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00.000] == LowBarParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :free, lo: nil, hi: nil} == LowBarParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == LowBarParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://ma.to/event/knight-moves-disco-chess-club-29-jul-2026" ==
               LowBarParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://ma.to/event/knight-moves-disco-chess-club-29-jul-2026" ==
               LowBarParser.details_url(event)
    end
  end
end
