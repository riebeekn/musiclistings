defmodule MusicListings.Parsing.VenueParsers.HandlebarParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HandlebarParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/handlebar/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/handlebar/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://calendar.apps.secureserver.net/v1/events/366947a0-303a-47c1-b561-5117b38b90ad/73550132-2f76-4daf-bb5b-1a9eff16e360/b0095722-7dba-4b95-8d4a-a1913fcbbe34" ==
               HandlebarParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = HandlebarParser.events(index_html)

      assert 26 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == HandlebarParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "kensington_shake_2024_09_28" == HandlebarParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "kensington_shake_2024_09_28" == HandlebarParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Kensington Shake" == HandlebarParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Kensington Shake",
               openers: []
             } == HandlebarParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-28] == HandlebarParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HandlebarParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[15:00:00] == HandlebarParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               HandlebarParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HandlebarParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == HandlebarParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://thehandlebar.ca/" ==
               HandlebarParser.details_url(event)
    end
  end
end
