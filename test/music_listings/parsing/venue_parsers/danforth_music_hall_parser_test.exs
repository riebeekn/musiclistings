defmodule MusicListings.Parsing.VenueParsers.DanforthMusicHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DanforthMusicHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/danforth_music_hall/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/danforth_music_hall/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> DanforthMusicHallParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://thedanforth.com" == DanforthMusicHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DanforthMusicHallParser.events(index_html)

      assert 68 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == DanforthMusicHallParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "post-17036" == DanforthMusicHallParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "post-17036" == DanforthMusicHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Northlane" == DanforthMusicHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Northlane",
               openers: ["Invent Animate", "Thornhill", "Windwaker"]
             } == DanforthMusicHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-05] == DanforthMusicHallParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:00:00] == DanforthMusicHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :range, lo: Decimal.new("30.00"), hi: Decimal.new("50.00")} ==
               DanforthMusicHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :all_ages == DanforthMusicHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https:\/\/www.ticketmaster.ca\/event\/1000603D7B880DBA" ==
               DanforthMusicHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == DanforthMusicHallParser.details_url(event)
    end
  end
end
