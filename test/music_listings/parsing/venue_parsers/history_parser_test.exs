defmodule MusicListings.Parsing.VenueParsers.HistoryParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HistoryParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/history/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/history/single_event.json")

    index_html = File.read!(index_file_path) |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> HistoryParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://api.livenation.com/graphql" == HistoryParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = HistoryParser.events(index_html)

      assert 75 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == HistoryParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "177Zv0G653rShzz" == HistoryParser.event_id(event)
    end

    # Each night of a run is listed as its own event under the same name
    test "returns a distinct id for each night of a run", %{index_html: index_html} do
      ids =
        index_html
        |> HistoryParser.events()
        |> Enum.filter(&(&1["name"] == "Geese - Getting Killed Again Tour"))
        |> Enum.map(&HistoryParser.event_id/1)

      assert ["1A8Zk3fGkeJq_g9", "1A8Zk3fGkeJragO"] == ids
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "177Zv0G653rShzz" == HistoryParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "KETTAMA" == HistoryParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "KETTAMA",
               openers: ["Loods"]
             } == HistoryParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-10-31] == HistoryParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HistoryParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == HistoryParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               HistoryParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HistoryParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/kettama-toronto-ontario-10-31-2026/event/100064B49ECDBE38" ==
               HistoryParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == HistoryParser.details_url(event)
    end
  end
end
