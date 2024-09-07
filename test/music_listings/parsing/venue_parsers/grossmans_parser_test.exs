defmodule MusicListings.Parsing.VenueParsers.GrossmansParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.GrossmansParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/grossmans/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/grossmans/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> GrossmansParser.events()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://grossmanstavern.com/events/list/page/1/" == GrossmansParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = GrossmansParser.events(index_html)

      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://grossmanstavern.com/events/list/page/2/" ==
               GrossmansParser.next_page_url(
                 index_html,
                 "https://grossmanstavern.com/events/list/page/1/"
               )
    end

    test "after grabbing page 3 it returns page 4", %{index_html: index_html} do
      assert "https://grossmanstavern.com/events/list/page/4/" ==
               GrossmansParser.next_page_url(
                 index_html,
                 "https://grossmanstavern.com/events/list/page/3/"
               )
    end

    test "returns the nil after grabbing page 4", %{index_html: index_html} do
      assert nil ==
               GrossmansParser.next_page_url(
                 index_html,
                 "https://grossmanstavern.com/events/list/page/4/"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "ganja_smugglers_2024_09_14" == GrossmansParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "ganja_smugglers_2024_09_14" == GrossmansParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Ganja Smugglers" == GrossmansParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Ganja Smugglers",
               openers: []
             } == GrossmansParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-14] == GrossmansParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == GrossmansParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == GrossmansParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               GrossmansParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == GrossmansParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == GrossmansParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://grossmanstavern.com/event/ganja-smugglers/" ==
               GrossmansParser.details_url(event)
    end
  end
end
