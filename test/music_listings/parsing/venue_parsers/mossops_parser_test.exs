defmodule MusicListings.Parsing.VenueParsers.MossopsParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MossopsParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/mossops/index.html")
    index_html = File.read!(index_file_path)

    events = MossopsParser.events(index_html)
    event = List.first(events)

    %{index_html: index_html, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://mossops.ca/" == MossopsParser.source_url()
    end
  end

  describe "events/1" do
    test "returns the live music series only", %{events: events} do
      assert [
               "Live at Mossop's ft. Alex Krolick",
               "Live at Mossop's ft. Seu",
               "Live at Mossop's ft. Christine",
               "Live at Mossop's ft. Jessica Ruffolo"
             ] == Enum.map(events, &MossopsParser.event_title/1)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == MossopsParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "mossops_7097" == MossopsParser.event_id(event)
    end

    test "is unique for each event", %{events: events} do
      ids = Enum.map(events, &MossopsParser.event_id/1)

      assert ids == Enum.uniq(ids)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "mossops_7097" == MossopsParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Live at Mossop's ft. Alex Krolick" == MossopsParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the performer without the series name", %{event: event} do
      assert %Performers{headliner: "Alex Krolick", openers: []} ==
               MossopsParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-11] == MossopsParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == MossopsParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the local start time", %{event: event} do
      assert ~T[18:30:00] == MossopsParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns unknown", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == MossopsParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == MossopsParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == MossopsParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event page on the hotel site", %{event: event} do
      assert "https://hotelvictoriatoronto.com/event/live-at-mossops-ft-alex-krolick/" ==
               MossopsParser.details_url(event)
    end
  end
end
