defmodule MusicListings.Parsing.VenueParsers.KoernerHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.KoernerHallParser

  @rcm_concerts_url "https://www.rcmusic.com/concerts?tps_activeFacetTab=Royal+Conservatory+Concerts&fq=eventvenue%7C%7CKoerner+Hall"
  @presented_by_others_url "https://www.rcmusic.com/concerts?tps_activeFacetTab=Concerts+Presented+By+Others&fq=eventvenue%7C%7CKoerner+Hall"

  setup do
    index_html = read_fixture("index.html")
    events = KoernerHallParser.events(index_html)

    %{
      index_html: index_html,
      last_page_html: read_fixture("last_page.html"),
      events: events,
      event: event_with_title(events, "Bruce Liu, piano")
    }
  end

  defp read_fixture(file_name),
    do: "#{File.cwd!()}/test/data/koerner_hall/#{file_name}" |> Path.expand() |> File.read!()

  defp event_with_title(events, title),
    do: Enum.find(events, &(KoernerHallParser.event_title(&1) == title))

  describe "source_url/0" do
    test "returns expected value" do
      assert @rcm_concerts_url == KoernerHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page of the current listing", %{index_html: index_html} do
      assert "#{@rcm_concerts_url}&page=2" ==
               KoernerHallParser.next_page_url(index_html, @rcm_concerts_url)

      assert "#{@rcm_concerts_url}&page=3" ==
               KoernerHallParser.next_page_url(index_html, "#{@rcm_concerts_url}&page=2")
    end

    test "moves on to the next listing once a short page is reached", %{
      last_page_html: last_page_html
    } do
      assert @presented_by_others_url ==
               KoernerHallParser.next_page_url(last_page_html, "#{@rcm_concerts_url}&page=6")
    end

    test "returns nil once the last listing runs out", %{last_page_html: last_page_html} do
      assert nil ==
               KoernerHallParser.next_page_url(
                 last_page_html,
                 "#{@presented_by_others_url}&page=2"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "426201" == KoernerHallParser.event_id(event)
    end

    test "returns a distinct id for every event on a page", %{events: events} do
      event_ids = Enum.map(events, &KoernerHallParser.event_id/1)

      assert 12 == event_ids |> Enum.uniq() |> Enum.count()
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "426201" == KoernerHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Bruce Liu, piano" == KoernerHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Bruce Liu, piano",
               openers: []
             } == KoernerHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-10-30] == KoernerHallParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == KoernerHallParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == KoernerHallParser.event_time(event)
    end

    test "returns an afternoon matinee start time", %{events: events} do
      event = event_with_title(events, "Garrick Ohlsson, piano")

      assert ~T[15:00:00] == KoernerHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == KoernerHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == KoernerHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.rcmusic.com/tickets/seats/426201" == KoernerHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.rcmusic.com/concert/bruce-liu-piano-426201" ==
               KoernerHallParser.details_url(event)
    end
  end
end
