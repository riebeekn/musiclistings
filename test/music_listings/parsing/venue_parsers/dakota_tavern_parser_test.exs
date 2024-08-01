defmodule MusicListings.Parsing.VenueParsers.DakotaTavernParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DakotaTavernParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/dakota_tavern/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/dakota_tavern/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> DakotaTavernParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.dakotatavern.ca" == DakotaTavernParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DakotaTavernParser.events(index_html)

      assert 25 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == DakotaTavernParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "oakridge_ave_w_high_flyer_lauren_carson_2024_07_25" ==
               DakotaTavernParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "OAKRIDGE AVE. w/ HIGH FLYER, LAUREN CARSON" == DakotaTavernParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "OAKRIDGE AVE. w/ HIGH FLYER, LAUREN CARSON",
               openers: []
             } == DakotaTavernParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-25] == DakotaTavernParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == DakotaTavernParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               DakotaTavernParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == DakotaTavernParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == DakotaTavernParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.dakotatavern.ca/shows/20240725-oakridgeave" ==
               DakotaTavernParser.details_url(event)
    end
  end
end
