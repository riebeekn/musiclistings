defmodule MusicListings.Parsing.VenueParsers.RogersParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RogersParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rogers/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/rogers/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> RogersParser.event()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.livenation.com/venue/KovZpa3Bbe/rogers-centre-events" ==
               RogersParser.source_url()
    end
  end

  describe "event/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RogersParser.event(index_html)

      assert 10 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RogersParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "G5vZZ9z6yjKEUdef-leppard-journey-the-summer-stadium-tour-with-cheap-trick" ==
               RogersParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Def Leppard / Journey: The Summer Stadium Tour with Cheap Trick" ==
               RogersParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Def Leppard",
               openers: ["Journey", "Cheap Trick"]
             } == RogersParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-02] == RogersParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:00:00] == RogersParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               RogersParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == RogersParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.livenation.com/event/G5vZZ9z6yjKEU/def-leppard-journey-the-summer-stadium-tour-with-cheap-trick" ==
               RogersParser.ticket_url(event)
    end
  end
end
