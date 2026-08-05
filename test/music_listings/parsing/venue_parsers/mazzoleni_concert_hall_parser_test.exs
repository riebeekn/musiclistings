defmodule MusicListings.Parsing.VenueParsers.MazzoleniConcertHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MazzoleniConcertHallParser

  @concert_hall_url "https://www.rcmusic.com/concerts?tps_activeFacetTab=Royal+Conservatory+Concerts&fq=eventvenue%7C%7CMazzoleni+Concert+Hall"
  @hall_url "https://www.rcmusic.com/concerts?tps_activeFacetTab=Royal+Conservatory+Concerts&fq=eventvenue%7C%7CMazzoleni+Hall"
  @other_public_events_url "https://www.rcmusic.com/concerts?tps_activeFacetTab=Other+Public+Events&fq=eventvenue%7C%7CMazzoleni+Hall"

  setup do
    index_html = read_fixture("index.html")
    events = MazzoleniConcertHallParser.events(index_html)

    %{
      index_html: index_html,
      last_page_html: read_fixture("last_page.html"),
      free_events: "free_events.html" |> read_fixture() |> MazzoleniConcertHallParser.events(),
      events: events,
      event: event_with_title(events, "Joaquin Valdepeñas Conducts")
    }
  end

  defp read_fixture(file_name) do
    "#{File.cwd!()}/test/data/mazzoleni_concert_hall/#{file_name}"
    |> Path.expand()
    |> File.read!()
  end

  defp event_with_title(events, title),
    do: Enum.find(events, &(MazzoleniConcertHallParser.event_title(&1) == title))

  defp event_on(events, date),
    do: Enum.find(events, &(MazzoleniConcertHallParser.event_date(&1) == date))

  describe "source_url/0" do
    test "returns expected value" do
      assert @concert_hall_url == MazzoleniConcertHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page of the current listing", %{index_html: index_html} do
      assert "#{@concert_hall_url}&page=2" ==
               MazzoleniConcertHallParser.next_page_url(index_html, @concert_hall_url)
    end

    test "walks the room's three listings in turn", %{last_page_html: last_page_html} do
      assert @hall_url ==
               MazzoleniConcertHallParser.next_page_url(
                 last_page_html,
                 "#{@concert_hall_url}&page=2"
               )

      assert @other_public_events_url ==
               MazzoleniConcertHallParser.next_page_url(last_page_html, @hall_url)

      assert nil ==
               MazzoleniConcertHallParser.next_page_url(
                 last_page_html,
                 "#{@other_public_events_url}&page=2"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "448601" == MazzoleniConcertHallParser.event_id(event)
    end

    test "returns a distinct id for every event on a page", %{events: events} do
      event_ids = Enum.map(events, &MazzoleniConcertHallParser.event_id/1)

      assert 12 == event_ids |> Enum.uniq() |> Enum.count()
    end

    test "falls back to title, date and time when the event isn't ticketed", %{
      free_events: free_events
    } do
      event =
        event_with_title(free_events, "RCM Summer Piano Festival: Master Class with Micah Yui")

      assert "rcm_summer_piano_festival_master_class_with_micah_yui_2026_08_17_13_00_00" ==
               MazzoleniConcertHallParser.event_id(event)
    end

    test "returns a distinct id for every unticketed event", %{free_events: free_events} do
      event_ids = Enum.map(free_events, &MazzoleniConcertHallParser.event_id/1)

      assert 12 == event_ids |> Enum.uniq() |> Enum.count()
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "448601" == MazzoleniConcertHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Joaquin Valdepeñas Conducts" == MazzoleniConcertHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Joaquin Valdepeñas Conducts",
               openers: []
             } == MazzoleniConcertHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-09-20] == MazzoleniConcertHallParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == MazzoleniConcertHallParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[15:00:00] == MazzoleniConcertHallParser.event_time(event)
    end

    test "returns a noon start time", %{free_events: free_events} do
      assert ~T[12:00:00] ==
               free_events |> event_on(~D[2026-08-15]) |> MazzoleniConcertHallParser.event_time()
    end

    test "returns a morning start time", %{free_events: free_events} do
      assert ~T[09:00:00] ==
               free_events |> event_on(~D[2026-08-13]) |> MazzoleniConcertHallParser.event_time()
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               MazzoleniConcertHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == MazzoleniConcertHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.rcmusic.com/tickets/seats/448601" ==
               MazzoleniConcertHallParser.ticket_url(event)
    end

    test "returns nil when the event isn't ticketed", %{free_events: free_events} do
      event =
        event_with_title(free_events, "RCM Summer Piano Festival: Master Class with Micah Yui")

      assert nil == MazzoleniConcertHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.rcmusic.com/concert/joaquin-valdepenas-conducts-448601" ==
               MazzoleniConcertHallParser.details_url(event)
    end
  end
end
