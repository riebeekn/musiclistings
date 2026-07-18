defmodule MusicListings.Parsing.VenueParsers.FreeTimesCafeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.FreeTimesCafeParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/free_times_cafe/index.json")

    index_json = File.read!(index_file_path)

    event =
      index_json
      |> FreeTimesCafeParser.events()
      |> Enum.find(&(&1["id"] == 3_889_439))

    %{index_json: index_json, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.freetimescafe.com/entertainment" == FreeTimesCafeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns only upcoming events in music categories", %{index_json: index_json} do
      events = FreeTimesCafeParser.events(index_json)

      # The fixture has 6 events: 4 upcoming music events (Music, Klezmer, Open Mic,
      # Jazz), 1 past music event, and 1 upcoming comedy event - both excluded.
      assert 4 == Enum.count(events)

      titles = Enum.map(events, &FreeTimesCafeParser.event_title/1)
      refute "SCARY GOOD COMEDY" in titles
      refute "Past Folk Show" in titles
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil ==
               FreeTimesCafeParser.next_page_url(
                 index_json,
                 "https://www.freetimescafe.com/entertainment"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "3889439" == FreeTimesCafeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "3889439" == FreeTimesCafeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "GLEN HORNBLAST & AIDAN DEVINE" == FreeTimesCafeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "GLEN HORNBLAST & AIDAN DEVINE",
               openers: []
             } == FreeTimesCafeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-15] == FreeTimesCafeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == FreeTimesCafeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == FreeTimesCafeParser.event_time(event)
    end

    test "handles start values that already include seconds", %{index_json: index_json} do
      event =
        index_json
        |> FreeTimesCafeParser.events()
        |> Enum.find(&(&1["id"] == 3_888_888))

      assert ~T[20:00:00] == FreeTimesCafeParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns unknown price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} == FreeTimesCafeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == FreeTimesCafeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns nil when the event has no link", %{event: event} do
      assert nil == FreeTimesCafeParser.ticket_url(event)
    end

    test "returns the sanitized link when present", %{index_json: index_json} do
      event =
        index_json
        |> FreeTimesCafeParser.events()
        |> Enum.find(&(&1["id"] == 3_999_001))

      assert "https://www.eventbrite.ca/e/open-mic-tickets-1234567890?aff=ebdssbdestsearch" ==
               FreeTimesCafeParser.ticket_url(event)
    end

    test "returns nil for the \"event_page\" placeholder link", %{index_json: index_json} do
      event =
        index_json
        |> FreeTimesCafeParser.events()
        |> Enum.find(&(&1["id"] == 3_888_888))

      assert nil == FreeTimesCafeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns nil when the event has no link", %{event: event} do
      assert nil == FreeTimesCafeParser.details_url(event)
    end
  end
end
