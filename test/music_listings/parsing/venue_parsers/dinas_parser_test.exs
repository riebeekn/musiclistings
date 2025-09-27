defmodule MusicListings.Parsing.VenueParsers.DinasParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DinasParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/dinas/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/dinas/single_event.json")

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
               DinasParser.source_url(),
               "https://www.dinastavern.com/api/open/GetItemsByMonth?month="
             )
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DinasParser.events(index_html)

      assert 11 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    setup do
      %{
        next_page_url:
          "https://www.dinastavern.com/api/open/GetItemsByMonth?month=9-2024&collectionId=68ae25e366b1226c46621c27&crumb=BSnq4OaZLAN4MjM2MDY2ZmIyYmRkZWJmYjA0MWM3YTk2ZTRmNmE0"
      }
    end

    test "returns the next page url", %{index_html: index_html, next_page_url: next_page_url} do
      assert next_page_url == DinasParser.next_page_url(index_html, nil)
    end

    test "returns nil when already processed the next page", %{
      index_html: index_html,
      next_page_url: next_page_url
    } do
      assert nil == DinasParser.next_page_url(index_html, next_page_url)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "68d1a6893043e954726b8b6c" == DinasParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "68d1a6893043e954726b8b6c" == DinasParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "MBG // CAMILLE LÉON" ==
               DinasParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "MBG // CAMILLE LÉON",
               openers: []
             } == DinasParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-09-24] == DinasParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == DinasParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00.988] == DinasParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               DinasParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == DinasParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == DinasParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.dinastavern.com/events/mbgcamilleleon" ==
               DinasParser.details_url(event)
    end
  end
end
