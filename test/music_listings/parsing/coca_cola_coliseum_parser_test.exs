defmodule MusicListings.Parsing.CocaColaColiseumParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.CocaColaColiseumParser
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/coca_cola_coliseum/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/coca_cola_coliseum/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> CocaColaColiseumParser.event_selector()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.coca-colacoliseum.com/events" == CocaColaColiseumParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "Coca Cola Coliseum" == CocaColaColiseumParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = CocaColaColiseumParser.event_selector(index_html)

      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == CocaColaColiseumParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "1000605AC088153E" == CocaColaColiseumParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Two Door Cinema Club" == CocaColaColiseumParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Two Door Cinema Club",
               openers: []
             } == CocaColaColiseumParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-31] == CocaColaColiseumParser.event_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == CocaColaColiseumParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               CocaColaColiseumParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == CocaColaColiseumParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https:\/\/www.ticketmaster.ca\/event\/1000605AC088153E?brand=CCC&camefrom=CFC_CCC_WEB_SCHEDULEPAGE_LINK_TWODOORCINEMACLUB-07\/31_312024" ==
               CocaColaColiseumParser.ticket_url(event)
    end
  end
end