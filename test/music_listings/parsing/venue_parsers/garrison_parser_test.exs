defmodule MusicListings.Parsing.VenueParsers.GarrisonParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.GarrisonParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/garrison/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/garrison/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> GarrisonParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "http://www.garrisontoronto.com/listings.html" == GarrisonParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = GarrisonParser.events(index_html)

      assert 32 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == GarrisonParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "mizmor_2024-07-19" == GarrisonParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "MIZMOR" == GarrisonParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "MIZMOR",
               openers: ["AMAROK", "A FLOCK NAMED MURDER", "WHERE THE LIGHT FADES"]
             } == GarrisonParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-19] == GarrisonParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:30:00] == GarrisonParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :fixed, hi: Decimal.new("34.88"), lo: Decimal.new("34.88")} ==
               GarrisonParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == GarrisonParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://inertia-entertainment.com/events/mizmor-amarok/" ==
               GarrisonParser.ticket_url(event)
    end
  end
end
