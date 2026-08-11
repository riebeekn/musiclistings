defmodule MusicListings.Parsing.VenueParsers.DrakeUndergroundParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DrakeUndergroundParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/drake_underground/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/drake_underground/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  # The index carries no event date, so a date can only come from the event's
  # own page.  These pull specific events out of the index fixture, each of
  # which maps to a different event page fixture in MusicListings.HttpClient.Test.
  defp event_with_link(index_html, link_fragment) do
    Enum.find(index_html, &String.contains?(&1["link"], link_fragment))
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://thedrake.ca/wp-json/wp/v2/event?event_location=67&per_page=100" ==
               DrakeUndergroundParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DrakeUndergroundParser.events(index_html)

      assert 86 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == DrakeUndergroundParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "3809" == DrakeUndergroundParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "3809" == DrakeUndergroundParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Boneheads" == DrakeUndergroundParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Boneheads",
               openers: []
             } == DrakeUndergroundParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the date from the event page, preferring it over the poster image", %{
      event: event
    } do
      # Page label says Jun. 26, the poster image file name says June-24
      assert ~D[2025-06-26] == DrakeUndergroundParser.event_date(event)
    end

    test "resolves the year against the publish date rather than today", %{
      index_html: index_html
    } do
      # Published 2025-06-28 for a Jul. 12 show.  DateHelpers.today/0 is mocked
      # to 2024-08-01 in tests, so a date derived from "now" could only ever
      # land in 2024 - this is the bug that resurrected past shows a year on.
      event = event_with_link(index_html, "with-love-ramaan")

      assert ~D[2025-07-12] == DrakeUndergroundParser.event_date(event)
    end

    test "falls back to the date in the poster image file name", %{index_html: index_html} do
      event = event_with_link(index_html, "i-feel-free")

      assert ~D[2025-07-04] == DrakeUndergroundParser.event_date(event)
    end

    test "raises rather than guessing when the page has no date", %{index_html: index_html} do
      event = event_with_link(index_html, "stacey-ryan")

      assert_raise RuntimeError, ~r/Unable to determine event date/, fn ->
        DrakeUndergroundParser.event_date(event)
      end
    end

    test "raises when the only date found is implausible for the listing", %{
      index_html: index_html
    } do
      # A Month-DD-YYYY belonging to some unrelated asset, years before the
      # listing was published
      event = event_with_link(index_html, "bo-staloch")

      assert_raise RuntimeError, ~r/Unable to determine event date/, fn ->
        DrakeUndergroundParser.event_date(event)
      end
    end

    test "raises when the event page can't be fetched", %{index_html: index_html} do
      event = event_with_link(index_html, "lovefoxy")

      assert_raise RuntimeError, ~r/Unable to determine event date/, fn ->
        DrakeUndergroundParser.event_date(event)
      end
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == DrakeUndergroundParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == DrakeUndergroundParser.event_time(event)
    end

    test "returns nil when the page carries no time", %{index_html: index_html} do
      event = event_with_link(index_html, "i-feel-free")

      assert nil == DrakeUndergroundParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               DrakeUndergroundParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == DrakeUndergroundParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == DrakeUndergroundParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://thedrake.ca/event/3809/" == DrakeUndergroundParser.details_url(event)
    end
  end
end
