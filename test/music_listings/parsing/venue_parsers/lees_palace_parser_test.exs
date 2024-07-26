defmodule MusicListings.Parsing.VenueParsers.LeesPalaceParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.LeesPalaceParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/lees_palace/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/lees_palace/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> LeesPalaceParser.event()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.leespalace.com/events" == LeesPalaceParser.source_url()
    end
  end

  describe "event/1" do
    test "returns expected events", %{index_html: index_html} do
      events = LeesPalaceParser.event(index_html)

      assert 57 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == LeesPalaceParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "whitehallw/thehighteens&wedding_2024-07-27" == LeesPalaceParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Whitehall w/ The High Teens & Wedding" == LeesPalaceParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Whitehall w/ The High Teens & Wedding",
               openers: []
             } == LeesPalaceParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-27] == LeesPalaceParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == LeesPalaceParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :fixed, hi: Decimal.new("20.00"), lo: Decimal.new("20.00")} ==
               LeesPalaceParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == LeesPalaceParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.showclix.com/event/whitehall-the-dance-cave" ==
               LeesPalaceParser.ticket_url(event)
    end
  end
end
