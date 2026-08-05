defmodule MusicListings.Parsing.VenueParsers.TemertyTheatreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.TemertyTheatreParser

  @rcm_concerts_url "https://www.rcmusic.com/concerts?tps_activeFacetTab=Royal+Conservatory+Concerts&fq=eventvenue%7C%7CTemerty+Theatre"
  @presented_by_others_url "https://www.rcmusic.com/concerts?tps_activeFacetTab=Concerts+Presented+By+Others&fq=eventvenue%7C%7CTemerty+Theatre"

  setup do
    index_html =
      "#{File.cwd!()}/test/data/temerty_theatre/index.html" |> Path.expand() |> File.read!()

    events = TemertyTheatreParser.events(index_html)

    %{
      index_html: index_html,
      events: events,
      event:
        Enum.find(
          events,
          &(TemertyTheatreParser.event_title(&1) ==
              "GGS New Music Ensemble: Bouchara: The Light of Other Worlds")
        )
    }
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert @rcm_concerts_url == TemertyTheatreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 4 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "moves on to the next listing when the page isn't full", %{index_html: index_html} do
      assert @presented_by_others_url ==
               TemertyTheatreParser.next_page_url(index_html, @rcm_concerts_url)
    end

    test "returns nil once the last listing runs out", %{index_html: index_html} do
      assert nil == TemertyTheatreParser.next_page_url(index_html, @presented_by_others_url)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "453601" == TemertyTheatreParser.event_id(event)
    end

    test "distinguishes two performances of the same programme on one day", %{events: events} do
      event_ids =
        events
        |> Enum.filter(
          &(TemertyTheatreParser.event_date(&1) == ~D[2027-01-24] and
              TemertyTheatreParser.event_title(&1) == "New Music Concerts: Blackout: in vain")
        )
        |> Enum.map(&TemertyTheatreParser.event_id/1)

      assert ["454001", "454601"] == Enum.sort(event_ids)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "453601" == TemertyTheatreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "GGS New Music Ensemble: Bouchara: The Light of Other Worlds" ==
               TemertyTheatreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "GGS New Music Ensemble: Bouchara: The Light of Other Worlds",
               openers: []
             } == TemertyTheatreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2027-01-23] == TemertyTheatreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == TemertyTheatreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == TemertyTheatreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == TemertyTheatreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == TemertyTheatreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.rcmusic.com/tickets/seats/453601" ==
               TemertyTheatreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.rcmusic.com/concert/ggs-new-music-ensemble-bouchara-the-light-of-other-worlds-453601" ==
               TemertyTheatreParser.details_url(event)
    end
  end
end
