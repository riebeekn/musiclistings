defmodule MusicListings.Parsing.VenueParsers.SauceParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.SauceParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/sauce/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> SauceParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://sauceonthedanforth.com/live-music" == SauceParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = SauceParser.events(index_html)

      assert 35 == Enum.count(events)
    end

    # Events are grouped under monthly headers - make sure a performer from a
    # later section is dated using that section's month/year.
    test "dates events using their monthly section header", %{index_html: index_html} do
      event =
        index_html
        |> SauceParser.events()
        |> Enum.find(&(&1["title"] == "Gary LaRocca"))

      assert ~D[2026-08-01] == SauceParser.event_date(event)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil ==
               SauceParser.next_page_url(index_html, "https://sauceonthedanforth.com/live-music")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "sauce_2026_07_04" == SauceParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "sauce_2026_07_04" == SauceParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Sal Indigo & Janet Christie" == SauceParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Sal Indigo & Janet Christie", openers: []} ==
               SauceParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-04] == SauceParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == SauceParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns nil (Sauce does not list per-event times)", %{event: event} do
      assert nil == SauceParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == SauceParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == SauceParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == SauceParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://sauceonthedanforth.com/live-music" == SauceParser.details_url(event)
    end
  end
end
