defmodule MusicListings.Parsing.VenueParsers.Bsmt254ParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.Bsmt254Parser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/bsmt254/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/bsmt254/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> Bsmt254Parser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.bsmt254.com/events/" == Bsmt254Parser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = Bsmt254Parser.events(index_html)

      assert 11 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == Bsmt254Parser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "the_bridge_with_milo_raad_ryan_king_valis_marivs_2024_09_20" ==
               Bsmt254Parser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "the_bridge_with_milo_raad_ryan_king_valis_marivs_2024_09_20" ==
               Bsmt254Parser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Bridge with Milo Raad, Ryan King, Valis & Marivs" ==
               Bsmt254Parser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Bridge with Milo Raad, Ryan King, Valis & Marivs",
               openers: []
             } == Bsmt254Parser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-20] == Bsmt254Parser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == Bsmt254Parser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the start time from the event's own page", %{index_html: index_html} do
      event = event_with_slug(index_html, "rhythm-n-bingo")

      assert ~T[20:00:00] == Bsmt254Parser.event_time(event)
    end

    test "returns the start time when the page lists no tickets", %{index_html: index_html} do
      event = event_with_slug(index_html, "not-a-bbq-x-hit-play")

      assert ~T[21:45:00] == Bsmt254Parser.event_time(event)
    end

    test "returns nil when the event page can't be fetched", %{event: event} do
      assert nil == Bsmt254Parser.event_time(event)
    end
  end

  describe "price/1" do
    # The venue writes its tiers with slashes, ie. "$12 adv / $15 door"
    test "reads a slash separated price as a range", %{index_html: index_html} do
      event = event_with_slug(index_html, "rhythm-n-bingo")

      assert %Price{format: :range, lo: Decimal.new("12"), hi: Decimal.new("15")} ==
               Bsmt254Parser.price(event)
    end

    # The blurbs run to prose, and "... / 7\" release" is a record, not a $7 tier
    test "ignores a slash that doesn't introduce another amount", %{index_html: index_html} do
      event = event_with_slug(index_html, "project-nowhere-night-2")

      assert %Price{format: :fixed, lo: Decimal.new("20"), hi: Decimal.new("20")} ==
               Bsmt254Parser.price(event)
    end

    test "still reads a pwyc price as pwyc", %{index_html: index_html} do
      event = event_with_slug(index_html, "project-nowhere-night-1")

      assert %Price{format: :pwyc, lo: nil, hi: nil} == Bsmt254Parser.price(event)
    end

    test "returns the price when the page lists no tickets", %{index_html: index_html} do
      event = event_with_slug(index_html, "not-a-bbq-x-hit-play")

      assert %Price{format: :fixed, lo: Decimal.new("20"), hi: Decimal.new("20")} ==
               Bsmt254Parser.price(event)
    end

    test "returns unknown when the event page can't be fetched", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               Bsmt254Parser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == Bsmt254Parser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the ticket url from the event's own page", %{index_html: index_html} do
      event = event_with_slug(index_html, "rhythm-n-bingo")

      assert "https://www.eventbrite.ca/e/rhythm-n-bingo-tickets-1996769144262?aff=oddtdtcreator" ==
               Bsmt254Parser.ticket_url(event)
    end

    # Some shows sell at the door only and link nothing but their instagram
    test "returns nil when the event page carries no ticket button", %{index_html: index_html} do
      event = event_with_slug(index_html, "not-a-bbq-x-hit-play")

      assert nil == Bsmt254Parser.ticket_url(event)
    end

    test "returns nil when the event page can't be fetched", %{event: event} do
      assert nil == Bsmt254Parser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.bsmt254.com/event/the-bridge-with-milo-raad-ryan-king-valis-marivs/" ==
               Bsmt254Parser.details_url(event)
    end
  end

  # The start time, the price and the ticket url only exist on an event's own
  # page - these pull specific events out of the listing fixture, each of which
  # maps to a different event page fixture in MusicListings.HttpClient.Test.
  # Selected by slug rather than title: several listing titles carry en dashes
  # and encoded ampersands.
  defp event_with_slug(index_html, slug) do
    index_html
    |> Bsmt254Parser.events()
    |> Enum.find(fn event ->
      event |> Bsmt254Parser.details_url() |> String.contains?("/#{slug}/")
    end)
  end
end
