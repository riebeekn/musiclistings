defmodule MusicListings.Parsing.VenueParsers.VelvetUndergroundParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.VelvetUndergroundParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/velvet_underground/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/velvet_underground/single_event.json")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://api.livenation.com/graphql" == VelvetUndergroundParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = VelvetUndergroundParser.events(index_html)

      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == VelvetUndergroundParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "1AvZZb9GkSiwxYN" == VelvetUndergroundParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "1AvZZb9GkSiwxYN" == VelvetUndergroundParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Army, The Navy - Gentle Hellraiser Tour" ==
               VelvetUndergroundParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Army, The Navy",
               openers: ["Aggie Miller"]
             } == VelvetUndergroundParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-03-30] == VelvetUndergroundParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == VelvetUndergroundParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == VelvetUndergroundParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               VelvetUndergroundParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == VelvetUndergroundParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/the-army-the-navy-gentle-hellraiser-toronto-ontario-03-30-2025/event/1000617CECCA2C23" ==
               VelvetUndergroundParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == VelvetUndergroundParser.details_url(event)
    end
  end
end
