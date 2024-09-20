defmodule MusicListings.Parsing.VenueParsers.MeridianArtsCentreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MeridianArtsCentreParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/meridian_arts_centre/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/meridian_arts_centre/single_event.json")

    index_html = File.read!(index_file_path) |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://cdn.contentful.com/spaces/nmxu5kj1b6ch/environments/master/entries?metadata.tags.sys.id%5Ball%5D=genreConcerts%2CmeridianArtsCentre&locale=en-US&include=1&limit=1000&order=-sys.createdAt" ==
               MeridianArtsCentreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = MeridianArtsCentreParser.events(index_html)

      assert 56 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == MeridianArtsCentreParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "from_the_caspian_sea_to_the_persian_gulf_2024_10_04" ==
               MeridianArtsCentreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "from_the_caspian_sea_to_the_persian_gulf_2024_10_04" ==
               MeridianArtsCentreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "From the Caspian Sea to the Persian Gulf" ==
               MeridianArtsCentreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "From the Caspian Sea to the Persian Gulf",
               openers: []
             } == MeridianArtsCentreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-10-04] == MeridianArtsCentreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [~D[2024-10-05]] == MeridianArtsCentreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == MeridianArtsCentreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               MeridianArtsCentreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == MeridianArtsCentreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/search?q=From%20the%20Caspian%20Sea%20to%20the%20Persian%20Gulf" ==
               MeridianArtsCentreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://tolive.com/Event-Details-Page/reference/Caspian-Sea-2024" ==
               MeridianArtsCentreParser.details_url(event)
    end
  end
end
