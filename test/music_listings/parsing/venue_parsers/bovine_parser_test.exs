defmodule MusicListings.Parsing.VenueParsers.BovineParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BovineParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/bovine/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/bovine/single_event.json")

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
               BovineParser.source_url(),
               "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Fwww.bovinesexclub.com%2F&w=235dbcca-3a0a-4622-a874-ce1dd5f36933"
             )
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = BovineParser.events(index_html)

      assert 50 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == BovineParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "m038i2v7" == BovineParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "m038i2v7" ==
               BovineParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "PUNKS IN SPACE -Devils Punch Bowl, Kevin Murphy, Stink Box" ==
               BovineParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "PUNKS IN SPACE -Devils Punch Bowl, Kevin Murphy, Stink Box",
               openers: []
             } == BovineParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-16] == BovineParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == BovineParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == BovineParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               BovineParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == BovineParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == BovineParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == BovineParser.details_url(event)
    end
  end
end
