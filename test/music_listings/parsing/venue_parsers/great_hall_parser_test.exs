defmodule MusicListings.Parsing.VenueParsers.GreatHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.GreatHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/great_hall/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/great_hall/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> GreatHallParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://thegreathall.ca/calendar/" == GreatHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = GreatHallParser.events(index_html)

      assert 31 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == GreatHallParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "event_7229" ==
               GreatHallParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "event_7229" ==
               GreatHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Brass Camel featuring A Short Walk to Pluto" == GreatHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Brass Camel featuring A Short Walk to Pluto",
               openers: []
             } == GreatHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-28] == GreatHallParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == GreatHallParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == GreatHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               GreatHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == GreatHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the ticket url from the event's own page", %{event: event} do
      assert "https://link.dice.fm/J8a9ff947024" == GreatHallParser.ticket_url(event)
    end

    test "unwraps a link protected vendor url", %{index_html: index_html} do
      event = event_with_title(index_html, "Nada Surf")

      assert "https://www.ticketmaster.ca/event/10006490C59A1D0A" ==
               GreatHallParser.ticket_url(event)
    end

    test "returns nil when the event page carries no ticket button", %{index_html: index_html} do
      event = event_with_title(index_html, "Casey MQ")

      assert nil == GreatHallParser.ticket_url(event)
    end

    test "returns nil when the event page can't be fetched", %{index_html: index_html} do
      event = event_with_title(index_html, "Kate Nash")

      assert nil == GreatHallParser.ticket_url(event)
    end

    # Nothing to fetch when the calendar renders the Info button with no link
    test "returns nil when the calendar links no event page" do
      event =
        "#{File.cwd!()}/test/data/great_hall/single_event_no_details_url.html"
        |> Path.expand()
        |> File.read!()
        |> GreatHallParser.events()
        |> List.first()

      assert nil == GreatHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://thegreathall.ca/event/brass-camel-featuring-a-short-walk-to-pluto/" ==
               GreatHallParser.details_url(event)
    end
  end

  # The vendor link only exists on an event's own page - these pull specific
  # events out of the calendar fixture, each of which maps to a different event
  # page fixture in MusicListings.HttpClient.Test.
  defp event_with_title(index_html, title) do
    index_html
    |> GreatHallParser.events()
    |> Enum.find(&(GreatHallParser.event_title(&1) == title))
  end
end
