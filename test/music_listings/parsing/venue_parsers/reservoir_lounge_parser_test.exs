defmodule MusicListings.Parsing.VenueParsers.ReservoirLoungeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ReservoirLoungeParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/reservoir_lounge/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> ReservoirLoungeParser.events()
      |> Enum.find(&(&1["id"] == "cc86ce50-76da-4726-bfd3-b8eb4d460d31"))

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.reservoirlounge.com/live-shows" == ReservoirLoungeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = ReservoirLoungeParser.events(index_html)

      assert 4 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == ReservoirLoungeParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "cc86ce50-76da-4726-bfd3-b8eb4d460d31" == ReservoirLoungeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "cc86ce50-76da-4726-bfd3-b8eb4d460d31" ==
               ReservoirLoungeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Shane Philips" == ReservoirLoungeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Shane Philips",
               openers: []
             } == ReservoirLoungeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-17] == ReservoirLoungeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == ReservoirLoungeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:30:00] == ReservoirLoungeParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == ReservoirLoungeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ReservoirLoungeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://reservoirlounge.com/#contact" == ReservoirLoungeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == ReservoirLoungeParser.details_url(event)
    end
  end
end
