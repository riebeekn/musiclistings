defmodule MusicListings.Parsing.VenueParsers.TDMusicHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.TDMusicHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/td_music_hall/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/td_music_hall/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> TDMusicHallParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://tdmusichall.mhrth.com/tickets/?page=1" == TDMusicHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = TDMusicHallParser.events(index_html)

      assert 8 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://tdmusichall.mhrth.com/tickets/?page=2" ==
               TDMusicHallParser.next_page_url(
                 index_html,
                 "https://tdmusichall.mhrth.com/tickets/?page=1"
               )

      assert "https://tdmusichall.mhrth.com/tickets/?page=3" ==
               TDMusicHallParser.next_page_url(
                 index_html,
                 "https://tdmusichall.mhrth.com/tickets/?page=2"
               )

      assert "https://tdmusichall.mhrth.com/tickets/?page=4" ==
               TDMusicHallParser.next_page_url(
                 index_html,
                 "https://tdmusichall.mhrth.com/tickets/?page=3"
               )

      assert "https://tdmusichall.mhrth.com/tickets/?page=5" ==
               TDMusicHallParser.next_page_url(
                 index_html,
                 "https://tdmusichall.mhrth.com/tickets/?page=4"
               )

      assert nil ==
               TDMusicHallParser.next_page_url(
                 index_html,
                 "https://tdmusichall.mhrth.com/tickets/?page=5"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "four_chords_and_the_truth_2025_11_13" == TDMusicHallParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "four_chords_and_the_truth_2025_11_13" == TDMusicHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Four Chords and the Truth" ==
               TDMusicHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Four Chords and the Truth",
               openers: []
             } == TDMusicHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-11-13] == TDMusicHallParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == TDMusicHallParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == TDMusicHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               TDMusicHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == TDMusicHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == TDMusicHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://tdmusichall.mhrth.com/tickets/four-chords-and-the-truth-nov/" ==
               TDMusicHallParser.details_url(event)
    end
  end
end
