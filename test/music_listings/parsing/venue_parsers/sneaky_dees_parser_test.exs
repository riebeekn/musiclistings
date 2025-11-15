defmodule MusicListings.Parsing.VenueParsers.SneakyDeesParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.SneakyDeesParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/sneaky_dees/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/sneaky_dees/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> SneakyDeesParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.sneakydees.com/events-copy" == SneakyDeesParser.source_url()
    end
  end

  describe "events/1" do
    test "returns only Live Music events", %{index_html: index_html} do
      events = SneakyDeesParser.events(index_html)

      assert 8 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == SneakyDeesParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "sneaky_dees_2025_11_23_19_00_00" == SneakyDeesParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "sneaky_dees_2025_11_23_19_00_00" == SneakyDeesParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "DREAMS Toronto Music Showcase" == SneakyDeesParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "DREAMS Toronto Music Showcase",
               openers: []
             } == SneakyDeesParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-11-23] == SneakyDeesParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == SneakyDeesParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == SneakyDeesParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               SneakyDeesParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == SneakyDeesParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://luma.com/qm3z41wx?locale=en-CA" ==
               SneakyDeesParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://luma.com/qm3z41wx?locale=en-CA" ==
               SneakyDeesParser.details_url(event)
    end
  end
end
