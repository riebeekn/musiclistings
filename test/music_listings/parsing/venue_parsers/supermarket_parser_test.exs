defmodule MusicListings.Parsing.VenueParsers.SupermarketParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.SupermarketParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/supermarket/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/supermarket/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Fwww.supermarketto.ca%2Fevents&w=03901524-2610-4337-ae40-0bb8e9f87389" ==
               SupermarketParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = SupermarketParser.events(index_html)

      assert 286 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == SupermarketParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "big_fam_jam_2024_08_06" == SupermarketParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "78a6a821-c71d-423a-b242-a0b7ec95cdcc" == SupermarketParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Big Fam Jam" ==
               SupermarketParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Big Fam Jam",
               openers: []
             } == SupermarketParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-06] == SupermarketParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [~D[2024-08-13]] == SupermarketParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == SupermarketParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               SupermarketParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == SupermarketParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == SupermarketParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.supermarketto.ca/events#calendar-03901524-2610-4337-ae40-0bb8e9f87389-event-78a6a821-c71d-423a-b242-a0b7ec95cdcc" ==
               SupermarketParser.details_url(event)
    end
  end
end
