defmodule MusicListings.Parsing.VenueParsers.RockpileParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RockpileParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rockpile/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/rockpile/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> RockpileParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://therockpile.ca" == RockpileParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RockpileParser.events(index_html)

      assert 44 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RockpileParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "rockpile_2024_10_12_19_00_00" ==
               RockpileParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "rockpile_2024_10_12_19_00_00" ==
               RockpileParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Blushing Brides / Tribute to The Rolling Stones, Led X Zeppelin - Led Zeppelin Tribute" ==
               RockpileParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner:
                 "Blushing Brides / Tribute to The Rolling Stones, Led X Zeppelin - Led Zeppelin Tribute",
               openers: []
             } == RockpileParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-10-12] == RockpileParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == RockpileParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == RockpileParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               RockpileParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :all_ages == RockpileParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketweb.ca/event/blushing-brides-tribute-to-the-rockpile-bar-nightclub-tickets/13888663?pl=rockpilewest&REFID=clientsitewp" ==
               RockpileParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://therockpile.ca/13888663/blushing-brides-tribute-to-the-rolling-stones-led-x-zeppelin-led-zeppelin-tribute" ==
               RockpileParser.details_url(event)
    end
  end
end
