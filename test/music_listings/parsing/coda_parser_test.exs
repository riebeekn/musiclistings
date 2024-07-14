defmodule MusicListings.Parsing.CodaParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.CodaParser
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/coda/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/coda/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> CodaParser.event_selector()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.codatoronto.com/events" == CodaParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "CODA" == CodaParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = CodaParser.event_selector(index_html)

      assert 15 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == CodaParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "leefoss_2024-07-13" == CodaParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "LEE FOSS" == CodaParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "LEE FOSS",
               openers: []
             } == CodaParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-13] == CodaParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == CodaParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               CodaParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == CodaParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == CodaParser.ticket_url(event)
    end
  end
end