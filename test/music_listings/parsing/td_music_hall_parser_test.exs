defmodule MusicListings.Parsing.TDMusicHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.TDMusicHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/td_music_hall/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/td_music_hall/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.mhrth.com/api/performance-feed/12" == TDMusicHallParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "TD Music Hall" == TDMusicHallParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = TDMusicHallParser.event_selector(index_html)

      assert 11 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == TDMusicHallParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "6231" == TDMusicHallParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Destra" ==
               TDMusicHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Destra",
               openers: []
             } == TDMusicHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-20] == TDMusicHallParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == TDMusicHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, hi: Decimal.new("0"), lo: Decimal.new("0")} ==
               TDMusicHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == TDMusicHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://tickets.mhrth.com/6230/6231" == TDMusicHallParser.ticket_url(event)
    end
  end
end
