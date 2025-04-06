defmodule MusicListings.Parsing.VenueParsers.CastrosLoungeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.CastrosLoungeParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/castros_lounge/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/castros_lounge/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> CastrosLoungeParser.events()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://castroslounge.com/events/" == CastrosLoungeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = CastrosLoungeParser.events(index_html)

      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://castroslounge.com/events/list/page/2/" ==
               CastrosLoungeParser.next_page_url(
                 index_html,
                 "https://castroslounge.com/events/"
               )
    end

    test "after grabbing page 3 it returns page 4", %{index_html: index_html} do
      assert "https://castroslounge.com/events/list/page/4/" ==
               CastrosLoungeParser.next_page_url(
                 index_html,
                 "https://castroslounge.com/events/list/page/3/"
               )
    end

    test "returns the nil after grabbing page 4", %{index_html: index_html} do
      assert nil ==
               CastrosLoungeParser.next_page_url(
                 index_html,
                 "https://castroslounge.com/events/list/page/4/"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "castros_lounge_2024_09_28_17_00_00" == CastrosLoungeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "castros_lounge_2024_09_28_17_00_00" == CastrosLoungeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Danny Marks" == CastrosLoungeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Danny Marks",
               openers: []
             } == CastrosLoungeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-28] == CastrosLoungeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CastrosLoungeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[17:00:00] == CastrosLoungeParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               CastrosLoungeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CastrosLoungeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == CastrosLoungeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://castroslounge.com/event/danny-marks-31/" ==
               CastrosLoungeParser.details_url(event)
    end
  end
end
