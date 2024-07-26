defmodule MusicListings.Parsing.VenueParsers.OperaHouseParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.OperaHouseParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/opera_house/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/opera_house/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> OperaHouseParser.event_selector()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://theoperahousetoronto.com/calendar" == OperaHouseParser.source_url()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = OperaHouseParser.event_selector(index_html)

      assert 62 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == OperaHouseParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "ZEAL&ARDORw/Gaerea,Zetra-2024-11-28" == OperaHouseParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "ZEAL & ARDOR w/ Gaerea, Zetra" == OperaHouseParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "ZEAL & ARDOR w/ Gaerea, Zetra",
               openers: []
             } == OperaHouseParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-11-28] == OperaHouseParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == OperaHouseParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               OperaHouseParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == OperaHouseParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/event/100060EAEEF1300A" ==
               OperaHouseParser.ticket_url(event)
    end
  end
end
