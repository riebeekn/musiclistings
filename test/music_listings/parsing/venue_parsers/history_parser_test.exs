defmodule MusicListings.Parsing.VenueParsers.HistoryParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HistoryParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/history/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/history/single_event.html")

    no_events_file_path = Path.expand("#{File.cwd!()}/test/data/history/no_events.html")

    index_html = File.read!(index_file_path)
    no_events_html = File.read!(no_events_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> HistoryParser.events()
      |> List.first()

    %{index_html: index_html, no_events_html: no_events_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.historytoronto.com/events/events_ajax/0" ==
               HistoryParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = HistoryParser.events(index_html)

      assert 6 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url advanced by the page's event count", %{
      index_html: index_html
    } do
      assert "https://www.historytoronto.com/events/events_ajax/6" ==
               HistoryParser.next_page_url(
                 index_html,
                 "https://www.historytoronto.com/events/events_ajax/0"
               )
    end

    test "returns nil when the page has no events", %{no_events_html: no_events_html} do
      assert nil ==
               HistoryParser.next_page_url(
                 no_events_html,
                 "https://www.historytoronto.com/events/events_ajax/6"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "lucky_daye_2024_07_31" == HistoryParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "lucky_daye_2024_07_31" == HistoryParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Lucky Daye" == HistoryParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Lucky Daye",
               openers: []
             } == HistoryParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-31] == HistoryParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HistoryParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == HistoryParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               HistoryParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HistoryParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/event/10006099F25B4189" ==
               HistoryParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.historytoronto.com/events/detail/lucky-daye" ==
               HistoryParser.details_url(event)
    end
  end
end
