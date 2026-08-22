defmodule MusicListings.Parsing.VenueParsers.PhoenixParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.PhoenixParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/phoenix/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/phoenix/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> PhoenixParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://thephoenixconcerttheatre.com/events/" == PhoenixParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = PhoenixParser.events(index_html)

      assert 16 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://thephoenixconcerttheatre.com/events/page/2/" ==
               PhoenixParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "phoenix_2024_08_30_19_00_00" == PhoenixParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "phoenix_2024_08_30_19_00_00" == PhoenixParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "LADYTRON" == PhoenixParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "LADYTRON",
               openers: []
             } == PhoenixParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-30] == PhoenixParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == PhoenixParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == PhoenixParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the price from the event's own page", %{index_html: index_html} do
      event = event_with_title(index_html, "Tinariwen")

      assert %Price{format: :variable, lo: Decimal.new("40"), hi: Decimal.new("50")} ==
               PhoenixParser.price(event)
    end

    # "$19 and up" is the venue's way of writing "$19+"
    test "reads an open ended price as variable", %{index_html: index_html} do
      event = event_with_title(index_html, "The Volunteers")

      assert %Price{format: :variable, lo: Decimal.new("19"), hi: Decimal.new("19")} ==
               PhoenixParser.price(event)
    end

    test "returns unknown when the event page lists no price", %{index_html: index_html} do
      event = event_with_title(index_html, "Homixide Gang")

      assert %Price{format: :unknown, lo: nil, hi: nil} == PhoenixParser.price(event)
    end

    test "returns unknown when the event page can't be fetched", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               PhoenixParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == PhoenixParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the ticket url from the event's own page", %{index_html: index_html} do
      event = event_with_title(index_html, "Tinariwen")

      assert "https://www.eventbrite.ca/e/1985722643882?aff=oddtdtcreator" ==
               PhoenixParser.ticket_url(event)
    end

    test "returns the ticket url even when no price is listed", %{index_html: index_html} do
      event = event_with_title(index_html, "Homixide Gang")

      assert "https://www.ticketmaster.ca/event/10006490C59A1D0A" ==
               PhoenixParser.ticket_url(event)
    end

    test "returns nil when the event page can't be fetched", %{event: event} do
      assert nil == PhoenixParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://thephoenixconcerttheatre.com/events/event/ladytron/" ==
               PhoenixParser.details_url(event)
    end
  end

  # The vendor link and the price only exist on an event's own page - these pull
  # specific events out of the index fixture, each of which maps to a different
  # event page fixture in MusicListings.HttpClient.Test.
  defp event_with_title(index_html, title) do
    index_html
    |> PhoenixParser.events()
    |> Enum.find(&(PhoenixParser.event_title(&1) == title))
  end
end
