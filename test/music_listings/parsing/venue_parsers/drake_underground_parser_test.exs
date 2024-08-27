defmodule MusicListings.Parsing.VenueParsers.DrakeUndergroundParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DrakeUndergroundParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/drake_underground/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/drake_underground/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.thedrake.ca/wp-json/drake/v2/drake_events" ==
               DrakeUndergroundParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DrakeUndergroundParser.events(index_html)

      assert 35 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == DrakeUndergroundParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "26643" == DrakeUndergroundParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "26643" == DrakeUndergroundParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Dead Tongues" == DrakeUndergroundParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Dead Tongues",
               openers: []
             } == DrakeUndergroundParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-10-01] == DrakeUndergroundParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == DrakeUndergroundParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == DrakeUndergroundParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               DrakeUndergroundParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == DrakeUndergroundParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://dice.fm/partner/drake-underground/event/lp6xl?dice_id=2918119&dice_channel=web&dice_tags=organic&dice_campaign=Drake%20Underground&dice_feature=mio_marketing&_branch_match_id=1262570201459111774&_branch_referrer=H4sIAAAAAAAAA8soKSkottLXz8nMy9ZLyUxO1UvL1fdNSjK0tEhKSjI2TgQA8N9m3yEAAAA%3D" ==
               DrakeUndergroundParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.thedrake.ca/events/dead-tongues" ==
               DrakeUndergroundParser.details_url(event)
    end
  end
end
