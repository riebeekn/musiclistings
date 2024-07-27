defmodule MusicListings.Parsing.VenueParsers.JazzBistroParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.JazzBistroParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/jazz_bistro/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/jazz_bistro/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> JazzBistroParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://jazzbistro.ca/event-calendar" == JazzBistroParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = JazzBistroParser.events(index_html)

      assert 53 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == JazzBistroParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "JB_Piano_Bar_Jim_Clayton_s_Jazz_Jukebox_2024_07_02" ==
               JazzBistroParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "JB Piano Bar: Jim Clayton's Jazz Jukebox" ==
               JazzBistroParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "JB Piano Bar: Jim Clayton's Jazz Jukebox",
               openers: []
             } == JazzBistroParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-02] == JazzBistroParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == JazzBistroParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               JazzBistroParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == JazzBistroParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://jazzbistro.ca/event/jb-piano-bar-jim-claytons-jazz-jukebox-20/" ==
               JazzBistroParser.ticket_url(event)
    end
  end
end
