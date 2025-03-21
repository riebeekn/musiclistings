defmodule MusicListings.Parsing.VenueParsers.ArraymusicParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ArraymusicParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/arraymusic/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/arraymusic/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> ArraymusicParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.arraymusic.ca/current-season/24-25-season-at-a-glance/" ==
               ArraymusicParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = ArraymusicParser.events(index_html)

      assert 19 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == ArraymusicParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "community_improvisation_workshops_with_allison_cameron_24_25_2024_09_30" ==
               ArraymusicParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "community_improvisation_workshops_with_allison_cameron_24_25_2024_09_30" ==
               ArraymusicParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Community Improvisation Workshops with Allison Cameron 24|25" ==
               ArraymusicParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Community Improvisation Workshops with Allison Cameron 24|25",
               openers: []
             } == ArraymusicParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-30] == ArraymusicParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [
               ~D[2024-10-28],
               ~D[2024-11-25],
               ~D[2025-01-27],
               ~D[2025-02-24],
               ~D[2025-03-31],
               ~D[2025-04-28],
               ~D[2025-05-26]
             ] == ArraymusicParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == ArraymusicParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               ArraymusicParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ArraymusicParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == ArraymusicParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.arraymusic.ca/community-improvisation-workshops-with-allison-cameron-2425/" ==
               ArraymusicParser.details_url(event)
    end
  end
end
