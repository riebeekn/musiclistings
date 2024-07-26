defmodule MusicListings.Parsing.VenueParsers.RebelParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RebelParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rebel/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/rebel/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://core.service.elfsight.com/p/boot/?page=https%3A%2F%2Frebeltoronto.com%2Fevents%2F&w=737e2434-3a70-460f-aa98-a1ec67d0b60b" ==
               RebelParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "Rebel" == RebelParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RebelParser.event_selector(index_html)

      assert 327 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RebelParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "lw7xanxp" == RebelParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "FRENCH MONTANA - GOTTA SEE IT TO BELIEVE IT TOUR" == RebelParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "FRENCH MONTANA - GOTTA SEE IT TO BELIEVE IT TOUR",
               openers: []
             } == RebelParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-15] == RebelParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == RebelParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, hi: Decimal.new("0"), lo: Decimal.new("0")} ==
               RebelParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == RebelParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://rebeltoronto.com/2024/05/15/french-montana-gotta-see-it-to-believe-it-tour/" ==
               RebelParser.ticket_url(event)
    end
  end
end
