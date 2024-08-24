defmodule MusicListings.Parsing.VenueParsers.ScotiabankParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ScotiabankParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/scotiabank/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/scotiabank/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> ScotiabankParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.scotiabankarena.com/events/events_ajax/0?category=1&venue=0&team=0&exclude=&per_page=63&came_from_page=event-list-page" ==
               ScotiabankParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = ScotiabankParser.events(index_html)

      assert 9 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == ScotiabankParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "billy_idol_rebel_yell_2024_08_29" == ScotiabankParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "billy_idol_rebel_yell_2024_08_29" == ScotiabankParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Billy Idol: Rebel Yell" == ScotiabankParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Billy Idol: Rebel Yell",
               openers: []
             } == ScotiabankParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-29] == ScotiabankParser.event_date(event)
    end
  end

  describe "event_end_date/1" do
    test "returns the final date of the event if a date range", %{event: event} do
      assert ~D[2024-09-02] == ScotiabankParser.event_end_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == ScotiabankParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               ScotiabankParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ScotiabankParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/event/1000608404DB45F2?brand=SBA&camefrom=CFC_SBA_WEB_SCHEDULEPAGE_LINK_BILLYIDOL-08/09_482024" ==
               ScotiabankParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.scotiabankarena.com/events/detail/billy-idol-rebel-yell" ==
               ScotiabankParser.details_url(event)
    end
  end
end
