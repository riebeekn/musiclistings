defmodule MusicListings.Parsing.VenueParsers.TimothysPubParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.TimothysPubParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/timothys_pub/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/timothys_pub/single_event.json")

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
               TimothysPubParser.source_url(),
               "https://tockify.com/api/ngevent?max=48&view=agenda&calname=robinbrem&start-inclusive=true&longForm=false&showAll=false&startms="
             )
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = TimothysPubParser.events(index_html)

      assert 25 = Enum.count(events)
    end

    test "filters out non-live music events", %{index_html: index_html} do
      events = TimothysPubParser.events(index_html)

      # All returned events should have the LIVE-@-TIMOTHY'S-PUB tag
      assert Enum.all?(events, fn event ->
               event
               |> get_in(["content", "tagset", "tags", "default"])
               |> Enum.member?("LIVE-@-TIMOTHY'S-PUB")
             end)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == TimothysPubParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id based on date only", %{event: event} do
      assert "timothys_pub_2025_11_18" == TimothysPubParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "timothys_pub_2025_11_18" ==
               TimothysPubParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "GIG RABBIT @ 7PM" ==
               TimothysPubParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "GIG RABBIT @ 7PM",
               openers: []
             } == TimothysPubParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-11-18] == TimothysPubParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == TimothysPubParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns nil since time is in the title", %{event: event} do
      assert nil == TimothysPubParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               TimothysPubParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == TimothysPubParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == TimothysPubParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == TimothysPubParser.details_url(event)
    end
  end
end
