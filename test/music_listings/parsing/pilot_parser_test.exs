defmodule MusicListings.Parsing.PilotParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.PilotParser
  alias MusicListings.Parsing.Price

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/pilot/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/pilot/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> PilotParser.event_selector()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.thepilot.ca/happening-at-the-pilot" == PilotParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "The Pilot" == PilotParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = PilotParser.event_selector(index_html)

      assert 9 == Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == PilotParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "NorbertBotosQuartet-2024-07-20" == PilotParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Norbert Botos Quartet" == PilotParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Norbert Botos Quartet",
               openers: []
             } == PilotParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-20] == PilotParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == PilotParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               PilotParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == PilotParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == PilotParser.ticket_url(event)
    end
  end
end
