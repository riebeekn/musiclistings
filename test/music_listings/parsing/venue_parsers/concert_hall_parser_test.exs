defmodule MusicListings.Parsing.VenueParsers.ConcertHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ConcertHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/concert_hall/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/concert_hall/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> ConcertHallParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://888yonge.com" == ConcertHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = ConcertHallParser.events(index_html)

      assert 37 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == ConcertHallParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "Crumb-2024-08-31" == ConcertHallParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Crumb" == ConcertHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Crumb",
               openers: []
             } == ConcertHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-31] == ConcertHallParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == ConcertHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               ConcertHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == ConcertHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https:\/\/www.ticketweb.ca\/event\/crumb-with-special-guests-the-concert-hall-tickets\/13407644?pl=MODO-LIVE" ==
               ConcertHallParser.ticket_url(event)
    end
  end
end
