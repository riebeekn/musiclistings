defmodule MusicListings.Parsing.VenueParsers.MonarchTavernParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MonarchTavernParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/monarch_tavern/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/monarch_tavern/single_event.json")

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
               MonarchTavernParser.source_url(),
               "https://tockify.com/api/ngevent?max=48&view=agenda&calname=monarchtavern&start-inclusive=true&longForm=false&showAll=false&startms="
             )
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = MonarchTavernParser.events(index_html)

      assert 29 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == MonarchTavernParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "59f4fea1df82fe17e4e1c2cf" == MonarchTavernParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Velvet Beach w/ Kicksie, Nutrients" ==
               MonarchTavernParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Velvet Beach w/ Kicksie, Nutrients",
               openers: []
             } == MonarchTavernParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-09] == MonarchTavernParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == MonarchTavernParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               MonarchTavernParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == MonarchTavernParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.showclix.com/event/velvet-beach-w-kicksie-nutrients?fbclid=IwZXh0bgNhZW0CMTAAAR17BU-juhb_cKEt6DTjTZZTKN2zCOz8J37qh1Pmfzx1ZWYchsXooULdRGQ_aem_ZmFrZWR1bW15MTZieXRlcw" ==
               MonarchTavernParser.ticket_url(event)
    end
  end
end
