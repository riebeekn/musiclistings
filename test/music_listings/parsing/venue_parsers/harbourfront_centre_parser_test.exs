defmodule MusicListings.Parsing.VenueParsers.HarbourfrontCentreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HarbourfrontCentreParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/harbourfront_centre/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/harbourfront_centre/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> HarbourfrontCentreParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://harbourfrontcentre.com/program/music/" ==
               HarbourfrontCentreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = HarbourfrontCentreParser.events(index_html)

      assert 7 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == HarbourfrontCentreParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "harbourfront_centre_2025_08_30" == HarbourfrontCentreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "harbourfront_centre_2025_08_30" == HarbourfrontCentreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Flavours by Fire: Live Music" == HarbourfrontCentreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Flavours by Fire: Live Music",
               openers: []
             } == HarbourfrontCentreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-08-30] == HarbourfrontCentreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [~D[2025-08-31], ~D[2025-09-01]] == HarbourfrontCentreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == HarbourfrontCentreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :free, lo: nil, hi: nil} ==
               HarbourfrontCentreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == HarbourfrontCentreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == HarbourfrontCentreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://harbourfrontcentre.com/event/live-music-flavours-by-fire-2025/" ==
               HarbourfrontCentreParser.details_url(event)
    end
  end
end
