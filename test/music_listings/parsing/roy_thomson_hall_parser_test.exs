defmodule MusicListings.Parsing.RoyThomsonHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.RoyThomsonHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/roy_thomson_hall/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/roy_thomson_hall/single_event.json")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.mhrth.com/api/performance-feed/12" == RoyThomsonHallParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "Roy Thomson Hall" == RoyThomsonHallParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RoyThomsonHallParser.event_selector(index_html)

      assert 26 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RoyThomsonHallParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "5958" == RoyThomsonHallParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "FINAL FANTASY VII REBIRTH Orchestra World Tour" ==
               RoyThomsonHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "FINAL FANTASY VII REBIRTH Orchestra World Tour",
               openers: []
             } == RoyThomsonHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-19] == RoyThomsonHallParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:30:00] == RoyThomsonHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, hi: Decimal.new("0"), lo: Decimal.new("0")} ==
               RoyThomsonHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == RoyThomsonHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://tickets.mhrth.com/5956/5958" == RoyThomsonHallParser.ticket_url(event)
    end
  end
end
