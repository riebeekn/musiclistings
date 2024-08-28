defmodule MusicListings.Parsing.VenueParsers.QueenElizabthTheatreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.QueenElizabthTheatreParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/queen_elizabeth_theatre/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/queen_elizabeth_theatre/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://gateway.admitone.com/embed/live-events?venueId=60ad698c2a3c42001744a78f&order=asc" ==
               QueenElizabthTheatreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = QueenElizabthTheatreParser.events(index_html)

      assert 31 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == QueenElizabthTheatreParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "kk_s_priest_accept_2024_09_10" == QueenElizabthTheatreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "kk_s_priest_accept_2024_09_10" == QueenElizabthTheatreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "KK's Priest / Accept" == QueenElizabthTheatreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "KK's Priest / Accept",
               openers: []
             } == QueenElizabthTheatreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-10] == QueenElizabthTheatreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == QueenElizabthTheatreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:45:00] == QueenElizabthTheatreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :range, hi: Decimal.new("115.00"), lo: Decimal.new("49.50")} ==
               QueenElizabthTheatreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == QueenElizabthTheatreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://admitone.com/events/kks-priest-toronto-9542448" ==
               QueenElizabthTheatreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == QueenElizabthTheatreParser.details_url(event)
    end
  end
end
