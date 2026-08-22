defmodule MusicListings.Parsing.VenueParsers.ElMocamboParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ElMocamboParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/el_mocambo/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/el_mocambo/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> ElMocamboParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://elmocambo.com/events-new/" == ElMocamboParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = ElMocamboParser.events(index_html)

      assert 10 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == ElMocamboParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "el_mocambo_2025_01_24_20_00_00" == ElMocamboParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "el_mocambo_2025_01_24_20_00_00" == ElMocamboParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Strangelove" == ElMocamboParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Strangelove",
               openers: []
             } == ElMocamboParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-01-24] == ElMocamboParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == ElMocamboParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == ElMocamboParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               ElMocamboParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ElMocamboParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the calendar's website icon url, without fetching the event page" do
      event =
        "#{File.cwd!()}/test/data/el_mocambo/single_event_with_website_icon.html"
        |> Path.expand()
        |> File.read!()
        |> ElMocamboParser.events()
        |> List.first()

      assert "https://www.eventbrite.ca/e/myles-castello-live-show-tickets-1994945923961" ==
               ElMocamboParser.ticket_url(event)
    end

    # The description's first link is the band's trailer, and the page's "add to
    # Google Calendar" href embeds a url encoded ticket link - neither should win
    # over the anchor the venue actually labelled "GET TICKETS HERE!".
    test "falls back to the labelled link on the event's page", %{index_html: index_html} do
      event = event_with_title(index_html, "Sousapalooza Day 1")

      assert "https://ticketscene.ca/events/57134/" == ElMocamboParser.ticket_url(event)
    end

    test "returns nil when the event page has no labelled ticket link", %{
      index_html: index_html
    } do
      event = event_with_title(index_html, "High Flyer Release Show")

      assert nil == ElMocamboParser.ticket_url(event)
    end

    test "returns nil when the event page can't be fetched", %{event: event} do
      assert nil == ElMocamboParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://elmocambo.com/event/strangelove/" ==
               ElMocamboParser.details_url(event)
    end
  end

  # Events that leave the calendar's website icon empty only carry a ticket link
  # on their own page - these pull such events out of the calendar fixture, each
  # of which maps to a different event page fixture in MusicListings.HttpClient.Test.
  defp event_with_title(index_html, title) do
    index_html
    |> ElMocamboParser.events()
    |> Enum.find(&(ElMocamboParser.event_title(&1) == title))
  end
end
