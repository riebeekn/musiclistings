defmodule MusicListings.Parsing.VenueParsers.FunctionBarParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.FunctionBarParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/function_bar/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/function_bar/single_event.json")

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
               FunctionBarParser.source_url(),
               "https://www.functionbar.ca/api/open/GetItemsByMonth?month="
             )
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = FunctionBarParser.events(index_html)

      assert 11 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    setup do
      %{
        next_page_url:
          "https://www.functionbar.ca/api/open/GetItemsByMonth?month=9-2024&collectionId=6756432299a26d16dca81cc2&crumb="
      }
    end

    test "returns the next page url", %{index_html: index_html, next_page_url: next_page_url} do
      assert next_page_url == FunctionBarParser.next_page_url(index_html, nil)
    end

    test "returns nil when already processed the next page", %{
      index_html: index_html,
      next_page_url: next_page_url
    } do
      assert nil == FunctionBarParser.next_page_url(index_html, next_page_url)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "6a35cc3b0af6370eee397edc" == FunctionBarParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "6a35cc3b0af6370eee397edc" == FunctionBarParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Bad Apples" == FunctionBarParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Bad Apples",
               openers: []
             } == FunctionBarParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-17] == FunctionBarParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == FunctionBarParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:30:00.154] == FunctionBarParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               FunctionBarParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == FunctionBarParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == FunctionBarParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.functionbar.ca/live-music/2026/07/17/the-bad-apples" ==
               FunctionBarParser.details_url(event)
    end
  end
end
