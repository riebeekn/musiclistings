defmodule MusicListings.Parsing.VenueParsers.AdelaideHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.AdelaideHallParser
  alias MusicListings.Parsing.VenueParsers.BaseParsers.AdmitOneParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/adelaide_hall/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/adelaide_hall/single_event.json")

    community_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/adelaide_hall/community_single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    community_event =
      community_event_file_path
      |> File.read!()
      |> Jason.decode!()
      |> AdmitOneParser.normalize_community_event()

    %{index_html: index_html, event: event, community_event: community_event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://gateway.admitone.com/embed/live-events?venueId=64a4349ec147b8570f9e83fc,5f2c38d9b49c224648301825,6182ec572490d0ef56a4adbe,6201607c4ece4990eeeb6a3c&order=asc" ==
               AdelaideHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = AdelaideHallParser.events(index_html)

      assert 19 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == AdelaideHallParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "adelaide_hall_2024_10_17_19_00_00" == AdelaideHallParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "adelaide_hall_2024_10_17_19_00_00" == AdelaideHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Jared Benjamin" == AdelaideHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Jared Benjamin",
               openers: []
             } == AdelaideHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-10-17] == AdelaideHallParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == AdelaideHallParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == AdelaideHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               AdelaideHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == AdelaideHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://admitone.com/events/jared-benjamin-toronto-9660223" ==
               AdelaideHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == AdelaideHallParser.details_url(event)
    end
  end

  describe "community (graphql) events" do
    test "event_title/1 returns the title", %{community_event: community_event} do
      assert "words can’t describe" == AdelaideHallParser.event_title(community_event)
    end

    test "event_date/1 converts the UTC startDate to eastern date", %{
      community_event: community_event
    } do
      assert ~D[2026-07-03] == AdelaideHallParser.event_date(community_event)
    end

    test "event_time/1 converts the UTC startDate to eastern time", %{
      community_event: community_event
    } do
      assert ~T[22:00:00] == AdelaideHallParser.event_time(community_event)
    end

    test "event_id/1 is built from venue and eastern datetime", %{
      community_event: community_event
    } do
      assert "adelaide_hall_2026_07_03_22_00_00" ==
               AdelaideHallParser.event_id(community_event)
    end

    test "ticket_url/1 points at the community event", %{community_event: community_event} do
      assert "https://community.admitone.com/events/6a32eba54a8da88ed9ec0f13" ==
               AdelaideHallParser.ticket_url(community_event)
    end

    test "age_restriction/1 is unknown", %{community_event: community_event} do
      assert :unknown == AdelaideHallParser.age_restriction(community_event)
    end
  end
end
