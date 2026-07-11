defmodule MusicListings.Parsing.VenueParsers.BambisParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BambisParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/bambis/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> BambisParser.events()
      |> Enum.find(&(&1["id"] == "2482363"))

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://ra.co/clubs/69282" == BambisParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = BambisParser.events(index_html)

      assert 7 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == BambisParser.next_page_url(index_html, "https://ra.co/clubs/69282")
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "bambis_2482363" == BambisParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "bambis_2482363" == BambisParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "HYMZ, Yao Yao, Prince Josh, Thanks for the Tears" == BambisParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "HYMZ, Yao Yao, Prince Josh, Thanks for the Tears",
               openers: []
             } == BambisParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-10] == BambisParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == BambisParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[22:00:00.000] == BambisParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == BambisParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == BambisParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == BambisParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://ra.co/events/2482363" == BambisParser.details_url(event)
    end
  end
end
