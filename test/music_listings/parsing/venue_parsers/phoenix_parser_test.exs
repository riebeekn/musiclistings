defmodule MusicListings.Parsing.VenueParsers.PhoenixParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.PhoenixParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/phoenix/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/phoenix/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> PhoenixParser.event()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://thephoenixconcerttheatre.com/events" == PhoenixParser.source_url()
    end
  end

  describe "event/1" do
    test "returns expected events", %{index_html: index_html} do
      events = PhoenixParser.event(index_html)

      assert 16 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://thephoenixconcerttheatre.com/events/page/2/" ==
               PhoenixParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "LADYTRON-2024-08-30" == PhoenixParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "LADYTRON" == PhoenixParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "LADYTRON",
               openers: []
             } == PhoenixParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-30] == PhoenixParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == PhoenixParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               PhoenixParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == PhoenixParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://thephoenixconcerttheatre.com/events/event/ladytron/" ==
               PhoenixParser.ticket_url(event)
    end
  end
end
