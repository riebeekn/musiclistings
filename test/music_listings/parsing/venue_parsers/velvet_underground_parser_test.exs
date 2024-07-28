defmodule MusicListings.Parsing.VenueParsers.VelvetUndergroundParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.VelvetUndergroundParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/velvet_underground/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/velvet_underground/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> VelvetUndergroundParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://thevelvet.ca/events" == VelvetUndergroundParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = VelvetUndergroundParser.events(index_html)

      assert 56 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://thevelvet.ca/events/page/2/" ==
               VelvetUndergroundParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "post-3623" == VelvetUndergroundParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Dangerous Summer" == VelvetUndergroundParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Dangerous Summer",
               openers: ["Bad Luck", "Rosecoloredworld"]
             } == VelvetUndergroundParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-15] == VelvetUndergroundParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:00:00] == VelvetUndergroundParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :range, lo: Decimal.new("25.00"), hi: Decimal.new("30.00")} ==
               VelvetUndergroundParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :all_ages == VelvetUndergroundParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https:\/\/www.ticketweb.ca\/event\/the-dangerous-summer-velvet-underground-tickets\/13465084?pl=embrace" ==
               VelvetUndergroundParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == VelvetUndergroundParser.details_url(event)
    end
  end
end
