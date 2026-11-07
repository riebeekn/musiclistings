defmodule MusicListings.Parsing.VenueParsers.BerczyTavernParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BerczyTavernParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/berczy_tavern/index.html")
    index_html = File.read!(index_file_path)

    events = BerczyTavernParser.events(index_html)
    event = List.first(events)
    evening_event = Enum.at(events, 1)

    %{index_html: index_html, events: events, event: event, evening_event: evening_event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.theberczy.com/piano-bar" == BerczyTavernParser.source_url()
    end
  end

  describe "events/1" do
    test "returns one event per set, not the calendar grid as well", %{events: events} do
      assert 29 == Enum.count(events)
    end

    test "has a unique id for each set, including two on the same day", %{events: events} do
      ids = Enum.map(events, &BerczyTavernParser.event_id/1)

      assert ids == Enum.uniq(ids)
      assert 2 == Enum.count(events, &(BerczyTavernParser.event_date(&1) == ~D[2026-11-07]))
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == BerczyTavernParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "berczy_tavern_2026_11_01_11_30_00" == BerczyTavernParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "berczy_tavern_2026_11_01_11_30_00" == BerczyTavernParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns the performer", %{event: event} do
      assert "Ciara Leah" == BerczyTavernParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Ciara Leah", openers: []} ==
               BerczyTavernParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-01] == BerczyTavernParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == BerczyTavernParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the start time of a brunch set", %{event: event} do
      assert ~T[11:30:00] == BerczyTavernParser.event_time(event)
    end

    test "returns the start time of an evening set", %{evening_event: evening_event} do
      assert ~T[19:00:00] == BerczyTavernParser.event_time(evening_event)
    end

    test "returns a time for every set", %{events: events} do
      refute Enum.any?(events, &is_nil(BerczyTavernParser.event_time(&1)))
    end
  end

  describe "price/1" do
    test "returns free as there is no cover charge", %{event: event} do
      assert %Price{format: :free, hi: nil, lo: nil} == BerczyTavernParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == BerczyTavernParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == BerczyTavernParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the schedule on the piano bar page", %{event: event} do
      assert "https://www.theberczy.com/piano-bar#live-piano-schedule" ==
               BerczyTavernParser.details_url(event)
    end
  end
end
