defmodule MusicListings.Parsing.VenueParsers.HorseshoeTavernParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HorseshoeTavernParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/horseshoe_tavern/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/horseshoe_tavern/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> HorseshoeTavernParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.horseshoetavern.com/events" == HorseshoeTavernParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = HorseshoeTavernParser.events(index_html)

      assert 51 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == HorseshoeTavernParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "philip_sayce_2024_09_06" == HorseshoeTavernParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "philip_sayce_2024_09_06" == HorseshoeTavernParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Philip Sayce" == HorseshoeTavernParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Philip Sayce",
               openers: []
             } == HorseshoeTavernParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-06] == HorseshoeTavernParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == HorseshoeTavernParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == HorseshoeTavernParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :fixed, lo: Decimal.new("30.00"), hi: Decimal.new("30.00")} ==
               HorseshoeTavernParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == HorseshoeTavernParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https:\/\/www.showclix.com\/event\/philip-sayce24" ==
               HorseshoeTavernParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.horseshoetavern.com/event/philip-sayce24" ==
               HorseshoeTavernParser.details_url(event)
    end
  end
end
