defmodule MusicListings.Parsing.VenueParsers.HardLuckParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HardLuckParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/hard_luck/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/hard_luck/single_event.json")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://api.livenation.com/graphql" == HardLuckParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = HardLuckParser.events(index_html)

      assert 14 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == HardLuckParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "1A8ZkHLk1abc01" == HardLuckParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "1A8ZkHLk1abc01" == HardLuckParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Black Dahlia Murder - Servitude Tour" == HardLuckParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Black Dahlia Murder",
               openers: ["After The Burial"]
             } == HardLuckParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-02-15] == HardLuckParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HardLuckParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == HardLuckParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               HardLuckParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HardLuckParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/the-black-dahlia-murder-toronto-ontario-02-15-2026/event/abc123" ==
               HardLuckParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == HardLuckParser.details_url(event)
    end
  end
end
