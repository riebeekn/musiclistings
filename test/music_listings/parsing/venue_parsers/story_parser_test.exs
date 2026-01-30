defmodule MusicListings.Parsing.VenueParsers.StoryParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.StoryParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/story/index.json")
    single_event_file_path = Path.expand("#{File.cwd!()}/test/data/story/single_event.json")

    index_body = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> StoryParser.events()
      |> List.first()

    %{index_body: index_body, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.storytoronto.ca/" == StoryParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_body: index_body} do
      events = StoryParser.events(index_body)

      assert 18 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_body: index_body} do
      assert nil == StoryParser.next_page_url(index_body, "https://www.storytoronto.ca/")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "0c037406-7546-418e-a9e5-7aa99bcea37a" == StoryParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "0c037406-7546-418e-a9e5-7aa99bcea37a" == StoryParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "MATTHIAS MEYER" == StoryParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "MATTHIAS MEYER",
               openers: []
             } == StoryParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-01-30] == StoryParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == StoryParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[22:00:00] == StoryParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :range, lo: Decimal.new("25.63"), hi: Decimal.new("71.75")} ==
               StoryParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == StoryParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.storytoronto.ca/event-details/matthias-meyer" ==
               StoryParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.storytoronto.ca/event-details/matthias-meyer" ==
               StoryParser.details_url(event)
    end
  end
end
