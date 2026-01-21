defmodule MusicListings.Parsing.VenueParsers.CodaParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.CodaParser

  # Mock date in tests is Aug 1, 2024. April 25 is >35 days before that,
  # so build_date_from_month_day_strings will return April 25, 2025.
  @expected_date ~D[2025-04-25]

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/coda/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/coda/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> CodaParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://codatoronto.com/events/" == CodaParser.source_url()
    end
  end

  describe "events/1" do
    test "returns only events with dates", %{index_html: index_html} do
      events = CodaParser.events(index_html)

      # index.html has 4 events total, but only 2 have dates
      assert 2 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == CodaParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "coda_2025_04_25" == CodaParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "coda_2025_04_25" == CodaParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "OMAR+" == CodaParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "OMAR+",
               openers: []
             } == CodaParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert @expected_date == CodaParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CodaParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == CodaParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               CodaParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CodaParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketweb.ca/event/omar-coda-tickets/14053944?pl=CODA" ==
               CodaParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.ticketweb.ca/event/omar-coda-tickets/14053944?pl=CODA" ==
               CodaParser.details_url(event)
    end
  end
end
