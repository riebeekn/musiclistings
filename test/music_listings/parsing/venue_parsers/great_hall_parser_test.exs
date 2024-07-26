defmodule MusicListings.Parsing.VenueParsers.GreatHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.GreatHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/great_hall/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/great_hall/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> GreatHallParser.event_selector()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://thegreathall.ca/calendar" == GreatHallParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "The Great Hall" == GreatHallParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = GreatHallParser.event_selector(index_html)

      assert 735 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == GreatHallParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "7229" == GreatHallParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Brass Camel featuring A Short Walk to Pluto" == GreatHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Brass Camel featuring A Short Walk to Pluto",
               openers: []
             } == GreatHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-28] == GreatHallParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == GreatHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, hi: Decimal.new("0"), lo: Decimal.new("0")} ==
               GreatHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == GreatHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == GreatHallParser.ticket_url(event)
    end
  end
end
