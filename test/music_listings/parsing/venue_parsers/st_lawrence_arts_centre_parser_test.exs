defmodule MusicListings.Parsing.VenueParsers.StLawrenceArtsCentreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.StLawrenceArtsCentreParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/st_lawrence_arts_centre/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/st_lawrence_arts_centre/single_event.json")

    index_html = File.read!(index_file_path) |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://cdn.contentful.com/spaces/nmxu5kj1b6ch/environments/master/entries?metadata.tags.sys.id%5Ball%5D=genreConcerts%2CstLawrenceArtsCentre&locale=en-US&include=1&limit=1000&order=-sys.createdAt" ==
               StLawrenceArtsCentreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = StLawrenceArtsCentreParser.events(index_html)

      assert 26 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == StLawrenceArtsCentreParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "abba_revisited_50th_anniversary_tour_2024_11_23" ==
               StLawrenceArtsCentreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "abba_revisited_50th_anniversary_tour_2024_11_23" ==
               StLawrenceArtsCentreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "ABBA Revisited: 50th Anniversary Tour" ==
               StLawrenceArtsCentreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "ABBA Revisited: 50th Anniversary Tour",
               openers: []
             } == StLawrenceArtsCentreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-11-23] == StLawrenceArtsCentreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == StLawrenceArtsCentreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == StLawrenceArtsCentreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               StLawrenceArtsCentreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == StLawrenceArtsCentreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/event/10006032EDDB6A73?brand=tolive" ==
               StLawrenceArtsCentreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://tolive.com/Event-Details-Page/reference/ABBA-2024" ==
               StLawrenceArtsCentreParser.details_url(event)
    end
  end
end
