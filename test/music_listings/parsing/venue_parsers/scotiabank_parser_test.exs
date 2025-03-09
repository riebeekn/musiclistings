defmodule MusicListings.Parsing.VenueParsers.ScotiabankParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ScotiabankParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/scotiabank/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/scotiabank/single_event.json")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://api.livenation.com/graphql" ==
               ScotiabankParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = ScotiabankParser.events(index_html)

      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == ScotiabankParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "1A8ZkAFGkdirxk4" == ScotiabankParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "1A8ZkAFGkdirxk4" == ScotiabankParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Disturbed: The Sickness 25th Anniversary Tour" ==
               ScotiabankParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Disturbed",
               openers: ["Daughtry", "Nothing More"]
             } == ScotiabankParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-04-07] == ScotiabankParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == ScotiabankParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:30:00] == ScotiabankParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               ScotiabankParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ScotiabankParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/disturbed-the-sickness-25th-anniversary-tour-toronto-ontario-04-07-2025/event/10006148EC7A2195" ==
               ScotiabankParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == ScotiabankParser.details_url(event)
    end
  end
end
