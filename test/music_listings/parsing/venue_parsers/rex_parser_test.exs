defmodule MusicListings.Parsing.VenueParsers.RexParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RexParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rex/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/rex/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert String.starts_with?(
               RexParser.source_url(),
               "https://www.therex.ca/api/open/GetItemsByMonth?month="
             )
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RexParser.events(index_html)

      assert 66 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RexParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "66953788463e0d7186889314" == RexParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "66953788463e0d7186889314" == RexParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Adrean Farrugia &  Brad Goode Quintet" ==
               RexParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Adrean Farrugia &  Brad Goode Quintet",
               openers: []
             } == RexParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-31] == RexParser.event_date(event)
    end
  end

  describe "event_end_date/1" do
    test "returns the final date of the event if a date range", %{event: event} do
      assert nil == RexParser.event_end_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:30:00.543] == RexParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               RexParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == RexParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == RexParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == RexParser.details_url(event)
    end
  end
end
