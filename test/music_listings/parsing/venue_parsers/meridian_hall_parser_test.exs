defmodule MusicListings.Parsing.VenueParsers.MeridianHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MeridianHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/meridian_hall/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/meridian_hall/single_event.json")

    index_html = File.read!(index_file_path) |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://cdn.contentful.com/spaces/nmxu5kj1b6ch/environments/master/entries?metadata.tags.sys.id%5Ball%5D=genreConcerts%2CmeridianHall&locale=en-US&include=1&limit=1000&order=-sys.createdAt" ==
               MeridianHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = MeridianHallParser.events(index_html)

      assert 52 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == MeridianHallParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "titanic_live_2025_02_13" ==
               MeridianHallParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "titanic_live_2025_02_13" ==
               MeridianHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Titanic Live" ==
               MeridianHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Titanic Live",
               openers: []
             } == MeridianHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-02-13] == MeridianHallParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [~D[2025-02-14], ~D[2025-02-15]] == MeridianHallParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:00:00] == MeridianHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               MeridianHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == MeridianHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/titanic-live-tickets/artist/2104277?venueId=131106&brand=tolive" ==
               MeridianHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://tolive.com/Event-Details-Page/reference/Titanic-Live-2025" ==
               MeridianHallParser.details_url(event)
    end
  end
end
