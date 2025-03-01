defmodule MusicListings.Parsing.VenueParsers.DprtmntParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DprtmntParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/dprtmnt/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/dprtmnt/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Fdprtmnt.com%2Fevents%2F&w=a969d3fe-6f22-4cb5-a7f1-1b03dad77e15" ==
               DprtmntParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DprtmntParser.events(index_html)

      assert 134 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == DprtmntParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "m66qqgz5" == DprtmntParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "m66qqgz5" == DprtmntParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "ROBIN SCHULZ" == DprtmntParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "ROBIN SCHULZ",
               openers: []
             } == DprtmntParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-03-07] == DprtmntParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == DprtmntParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[23:45:00] == DprtmntParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               DprtmntParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == DprtmntParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == DprtmntParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://dprtmnt.com/robin-schulz/" ==
               DprtmntParser.details_url(event)
    end
  end
end
