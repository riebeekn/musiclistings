defmodule MusicListings.Parsing.VenueParsers.DprtmntParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DprtmntParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/dprtmnt/index.html")
    single_event_file_path = Path.expand("#{File.cwd!()}/test/data/dprtmnt/single_event.html")

    index_html = File.read!(index_file_path)
    event = File.read!(single_event_file_path)

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://dprtmnt.com/events/" == DprtmntParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DprtmntParser.events(index_html)

      assert 11 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == DprtmntParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert "4270" == DprtmntParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert "4270" == DprtmntParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert "CHUS & CEBALLOS" == DprtmntParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      [event] = DprtmntParser.events(event)

      assert %Performers{
               headliner: "CHUS & CEBALLOS",
               openers: []
             } == DprtmntParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert ~D[2025-01-16] == DprtmntParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert [] == DprtmntParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert nil == DprtmntParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      [event] = DprtmntParser.events(event)

      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               DprtmntParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert :nineteen_plus == DprtmntParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      [event] = DprtmntParser.events(event)

      assert "https://www.ticketweb.ca/event/chus-ceballos-dprtmnt-tickets/13986904?pl=ink" ==
               DprtmntParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      [event] = DprtmntParser.events(event)
      assert "https://dprtmnt.com/events/" == DprtmntParser.details_url(event)
    end
  end
end
