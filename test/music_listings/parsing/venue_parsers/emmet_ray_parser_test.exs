defmodule MusicListings.Parsing.VenueParsers.EmmetRayParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.EmmetRayParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/emmet_ray/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/emmet_ray/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> EmmetRayParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.theemmetray.com/entertainment/events-2023/" ==
               EmmetRayParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = EmmetRayParser.events(index_html)

      assert 35 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == EmmetRayParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "emmet_ray_2024_10_21_21_00_00" ==
               EmmetRayParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "emmet_ray_2024_10_21_21_00_00" ==
               EmmetRayParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "whiiiiiiirrrllll, Jazz inspired by Daft Punk & French House" ==
               EmmetRayParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "whiiiiiiirrrllll, Jazz inspired by Daft Punk & French House",
               openers: []
             } == EmmetRayParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-10-21] == EmmetRayParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == EmmetRayParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == EmmetRayParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               EmmetRayParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == EmmetRayParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == EmmetRayParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.theemmetray.com/event/whiiiiiiirrrllll-jazz-inspired-by-house-dance-music-specifically-the-music-of-french-house-duo-daft-punk-and-free-improvisation/" ==
               EmmetRayParser.details_url(event)
    end
  end
end
