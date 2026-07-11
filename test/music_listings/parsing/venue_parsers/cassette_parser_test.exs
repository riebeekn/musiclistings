defmodule MusicListings.Parsing.VenueParsers.CassetteParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.CassetteParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/cassette/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> CassetteParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.cassetteto.com/events" == CassetteParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = CassetteParser.events(index_html)

      assert 47 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil ==
               CassetteParser.next_page_url(index_html, "https://www.cassetteto.com/events")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "cassette_2026_07_10_20_30_00" == CassetteParser.event_id(event)
    end

    test "returns a unique id for each event", %{index_html: index_html} do
      event_ids =
        index_html
        |> CassetteParser.events()
        |> Enum.map(&CassetteParser.event_id/1)

      assert 47 == event_ids |> Enum.uniq() |> Enum.count()
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "cassette_2026_07_10_20_30_00" == CassetteParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Tumako: Live at Cassette" == CassetteParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Tumako: Live at Cassette", openers: []} ==
               CassetteParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-10] == CassetteParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CassetteParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:30:00] == CassetteParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == CassetteParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CassetteParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == CassetteParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.cassetteto.com/events/tumako-live-at-cassette-nfa8b-ns4zh" ==
               CassetteParser.details_url(event)
    end
  end
end
