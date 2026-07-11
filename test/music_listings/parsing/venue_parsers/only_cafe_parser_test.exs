defmodule MusicListings.Parsing.VenueParsers.OnlyCafeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.OnlyCafeParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/only_cafe/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> OnlyCafeParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.theonlycafe.com/shows" == OnlyCafeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = OnlyCafeParser.events(index_html)

      assert 4 == Enum.count(events)
    end

    # Google Sites splits text across spans, so this date renders as
    # "Fri day July 1 0 th" - make sure we still parse it as July 10.
    test "parses a space-split date", %{index_html: index_html} do
      event = index_html |> OnlyCafeParser.events() |> Enum.at(1)

      assert "Kriel, Goldstein & Slavin" == OnlyCafeParser.event_title(event)
      assert ~D[2024-07-10] == OnlyCafeParser.event_date(event)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == OnlyCafeParser.next_page_url(index_html, "https://www.theonlycafe.com/shows")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "only_cafe_2024_07_09_19_00_00" == OnlyCafeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "only_cafe_2024_07_09_19_00_00" == OnlyCafeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Jake B.K. Trio" == OnlyCafeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Jake B.K. Trio", openers: []} ==
               OnlyCafeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-09] == OnlyCafeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == OnlyCafeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == OnlyCafeParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == OnlyCafeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == OnlyCafeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == OnlyCafeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.theonlycafe.com/shows" == OnlyCafeParser.details_url(event)
    end
  end
end
