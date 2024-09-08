defmodule MusicListings.Parsing.VenueParsers.TranzacParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.TranzacParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/tranzac/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/tranzac/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> TranzacParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.tranzac.org/events/month/2024-08/" == TranzacParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = TranzacParser.events(index_html)

      assert 69 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://www.tranzac.org/events/month/2024-09/" ==
               TranzacParser.next_page_url(index_html, nil)
    end

    test "returns nil when already processed the next page", %{index_html: index_html} do
      assert nil ==
               TranzacParser.next_page_url(
                 index_html,
                 "https://www.tranzac.org/events/month/2024-09/"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "brodie_west_quintet_2024_09_11" ==
               TranzacParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "brodie_west_quintet_2024_09_11" ==
               TranzacParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Brodie West Quintet" ==
               TranzacParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Brodie West Quintet",
               openers: []
             } == TranzacParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-11] == TranzacParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == TranzacParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == TranzacParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               TranzacParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == TranzacParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == TranzacParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.tranzac.org/event/brodie-west-quintet/" ==
               TranzacParser.details_url(event)
    end
  end
end
