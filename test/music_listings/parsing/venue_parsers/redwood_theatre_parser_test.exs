defmodule MusicListings.Parsing.VenueParsers.RedwoodTheatreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RedwoodTheatreParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/redwood_theatre/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/redwood_theatre/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> RedwoodTheatreParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.theredwoodtheatre.com/" == RedwoodTheatreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RedwoodTheatreParser.events(index_html)

      assert 18 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RedwoodTheatreParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "63fbd282-5832-4d80-bf29-645d2745f820" ==
               RedwoodTheatreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "63fbd282-5832-4d80-bf29-645d2745f820" ==
               RedwoodTheatreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Sudan Remember Us" == RedwoodTheatreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Sudan Remember Us",
               openers: []
             } == RedwoodTheatreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-01-17] == RedwoodTheatreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == RedwoodTheatreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == RedwoodTheatreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               RedwoodTheatreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == RedwoodTheatreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the vendor url when the venue sells through one", %{event: event} do
      assert "https://actionnetwork.org/ticketed_events/sudan-remember-us-the-redwood-theatre-january-17?clear_id=true" ==
               RedwoodTheatreParser.ticket_url(event)
    end

    # Most of this venue's shows are ticketed by Wix itself rather than an
    # outside vendor, and are bought on the event's own page
    test "returns the event page when wix sells the tickets", %{index_html: index_html} do
      event = event_with_title(index_html, "SexBandit")

      assert "https://www.theredwoodtheatre.com/event-details/sexbandit" ==
               RedwoodTheatreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.theredwoodtheatre.com/event-details/film-screening-gaza-doctors-under-attack-1" ==
               RedwoodTheatreParser.details_url(event)
    end
  end

  defp event_with_title(index_html, title) do
    index_html
    |> RedwoodTheatreParser.events()
    |> Enum.find(fn event -> RedwoodTheatreParser.event_title(event) == title end)
  end
end
