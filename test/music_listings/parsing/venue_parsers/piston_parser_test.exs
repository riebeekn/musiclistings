defmodule MusicListings.Parsing.VenueParsers.PistonParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.PistonParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/the_piston/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/the_piston/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert String.starts_with?(
               PistonParser.source_url(),
               "https://www.thepiston.ca/api/open/GetItemsByMonth?month="
             )
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = PistonParser.events(index_html)

      assert 17 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    setup do
      %{
        next_page_url:
          "https://www.thepiston.ca/api/open/GetItemsByMonth?month=9-2024&collectionId=69cc145c7359594a10c2710c&crumb="
      }
    end

    test "returns the next page url", %{index_html: index_html, next_page_url: next_page_url} do
      assert next_page_url == PistonParser.next_page_url(index_html, nil)
    end

    test "returns nil when already processed the next page", %{
      index_html: index_html,
      next_page_url: next_page_url
    } do
      assert nil == PistonParser.next_page_url(index_html, next_page_url)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "6a089fe2c054f434c6bccd83" == PistonParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "6a089fe2c054f434c6bccd83" == PistonParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Rising JRock 2026" == PistonParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Rising JRock 2026",
               openers: []
             } == PistonParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-19] == PistonParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == PistonParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00.262] == PistonParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               PistonParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == PistonParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == PistonParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.thepiston.ca/calendar/zjxsxq37dvy0xw4m9u5lien1zkylb3" ==
               PistonParser.details_url(event)
    end
  end
end
