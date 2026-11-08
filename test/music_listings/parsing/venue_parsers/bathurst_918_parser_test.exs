defmodule MusicListings.Parsing.VenueParsers.Bathurst918ParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.Bathurst918Parser

  setup do
    index_html =
      "#{File.cwd!()}/test/data/bathurst_918/index.html"
      |> Path.expand()
      |> File.read!()

    events = Bathurst918Parser.events(index_html)

    event = Enum.find(events, &(&1.date == ~D[2026-11-27]))

    %{index_html: index_html, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.918bathurst.com/events" == Bathurst918Parser.source_url()
    end
  end

  describe "events/1" do
    test "returns the events in the upcoming events grid", %{events: events} do
      assert [
               {~D[2026-11-12], "Storytime - Chapter Love"},
               {~D[2026-11-13], "Liana Zhen-Ai & Astrid Sonne \"Normal Dreams\""},
               {~D[2026-11-15], "LIELOS By Levram"},
               {~D[2026-11-20], "Swash & Serif Typography Conference"},
               {~D[2026-11-27], "Westelaken - In it for the Lack - Album Release"},
               {~D[2026-12-11],
                "Hope for the Holidays: A Celebration of KLASSE Theatricals 1st Season"},
               {~D[2026-12-21], "Jennifer Castle Winter Solstice Show"}
             ] == Enum.map(events, &{&1.date, &1.title})
    end

    test "ignores the calendar's card for the selected day", %{events: events} do
      # Nov 12 is in both the selected day's panel and the grid
      assert 1 == Enum.count(events, &(&1.title == "Storytime - Chapter Love"))
    end

    test "returns no events for a page that hasn't rendered its listing" do
      assert [] == Bathurst918Parser.events(~s(<html><body><div id="root"></div></body></html>))
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == Bathurst918Parser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "918_bathurst_westelaken_in_it_for_the_lack_album_release_2026_11_27" ==
               Bathurst918Parser.event_id(event)
    end

    test "returns a unique id per event", %{events: events} do
      ids = Enum.map(events, &Bathurst918Parser.event_id/1)

      assert ids == Enum.uniq(ids)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "918_bathurst_westelaken_in_it_for_the_lack_album_release_2026_11_27" ==
               Bathurst918Parser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Westelaken - In it for the Lack - Album Release" ==
               Bathurst918Parser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Westelaken - In it for the Lack - Album Release",
               openers: []
             } == Bathurst918Parser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-27] == Bathurst918Parser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns no additional dates", %{event: event} do
      assert [] == Bathurst918Parser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns nil, as the time is only in the event's popup", %{event: event} do
      assert nil == Bathurst918Parser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :fixed, lo: Decimal.new("20.00"), hi: Decimal.new("20.00")} ==
               Bathurst918Parser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == Bathurst918Parser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns nil, as the ticket link is only in the event's popup", %{event: event} do
      assert nil == Bathurst918Parser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the events page", %{event: event} do
      assert "https://www.918bathurst.com/events" == Bathurst918Parser.details_url(event)
    end
  end
end
