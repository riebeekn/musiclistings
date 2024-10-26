defmodule MusicListings.Parsing.VenueParsers.RogersStadiumParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RogersStadiumParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rogers_stadium/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/rogers_stadium/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> RogersStadiumParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.livenation.com/venue/KovZ917ARzt/rogers-stadium-events" ==
               RogersStadiumParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RogersStadiumParser.events(index_html)

      assert 4 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RogersStadiumParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "rogers_stadium_2025_08_25_19_30_00" ==
               RogersStadiumParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "rogers_stadium_2025_08_25_19_30_00" ==
               RogersStadiumParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "OASIS LIVE '25" ==
               RogersStadiumParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Oasis",
               openers: ["Cage The Elephant"]
             } == RogersStadiumParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-08-25] == RogersStadiumParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == RogersStadiumParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:30:00] == RogersStadiumParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               RogersStadiumParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == RogersStadiumParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.livenation.com/event/1A8ZkAvGkdh9N8l/oasis-live-25" ==
               RogersStadiumParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == RogersStadiumParser.details_url(event)
    end
  end
end
