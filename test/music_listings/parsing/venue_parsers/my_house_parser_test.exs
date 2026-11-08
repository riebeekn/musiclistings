defmodule MusicListings.Parsing.VenueParsers.MyHouseParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MyHouseParser

  setup do
    index_html =
      "#{File.cwd!()}/test/data/my_house/index.html"
      |> Path.expand()
      |> File.read!()

    events = MyHouseParser.events(index_html)

    event = Enum.find(events, &(&1.date == ~D[2026-11-06]))

    %{index_html: index_html, events: events, event: event}
  end

  defp calendar(month_heading, rows) do
    h4s = Enum.map_join(rows, "", &"<h4><span>#{&1}</span></h4>")
    "<html><body><h3><span>#{month_heading}</span></h3>#{h4s}</body></html>"
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://myhouseinthejunction.com/live-entertainment" == MyHouseParser.source_url()
    end
  end

  describe "events/1" do
    test "pairs each date with the show after it", %{events: events} do
      assert [
               {~D[2026-11-06], "GLENDALE ONE"},
               {~D[2026-11-11], "Darcy Windover"},
               {~D[2026-11-13], "KOOK MAMA"},
               {~D[2026-11-14], "STEVE KOVEN TRIO"},
               {~D[2026-11-18], "DARCY WINDOVER"},
               {~D[2026-11-20], "FLINTLOCK"},
               {~D[2026-11-21], "ROBYN BLACK"},
               {~D[2026-11-25], "DARCY WINDOVER"},
               {~D[2026-11-27], "MATT PINES TRIO"},
               {~D[2026-11-28], "JUNCTION CITY ALL STARS"},
               # Left over from the previous month, dropped by the crawler as past
               {~D[2026-10-23], "FLINTLOCK"},
               {~D[2026-10-24], "JUNCTION CITY ALL STARS"},
               {~D[2026-10-28], "DARCY WINDOVER"}
             ] == Enum.map(events, &{&1.date, &1.title})
    end

    test "skips private functions and burlesque nights", %{events: events} do
      dates = Enum.map(events, & &1.date)

      refute ~D[2026-11-07] in dates
      refute ~D[2026-11-19] in dates
    end

    test "moves a show across a new year from the calendar's month into the next year" do
      body =
        calendar("DECEMBER 2026", [
          "Thursday December 31, 8PM",
          "NYE BAND",
          "Friday January 8, 8PM",
          "JAN BAND"
        ])

      assert [~D[2026-12-31], ~D[2027-01-08]] ==
               body |> MyHouseParser.events() |> Enum.map(& &1.date)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == MyHouseParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "my_house_2026_11_06" == MyHouseParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "my_house_2026_11_06" == MyHouseParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns the title without its emoji", %{event: event} do
      assert "GLENDALE ONE" == MyHouseParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "GLENDALE ONE", openers: []} ==
               MyHouseParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-06] == MyHouseParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns no additional dates", %{event: event} do
      assert [] == MyHouseParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event time", %{events: events, event: event} do
      assert ~T[20:00:00] == MyHouseParser.event_time(event)

      assert ~T[18:30:00] ==
               events |> Enum.find(&(&1.date == ~D[2026-11-11])) |> MyHouseParser.event_time()
    end

    test "returns nil when the date has no time" do
      [event] =
        "NOVEMBER 2026"
        |> calendar(["Saturday November 7", "GLENDALE ONE"])
        |> MyHouseParser.events()

      assert nil == MyHouseParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns unknown", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} == MyHouseParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == MyHouseParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns nil", %{event: event} do
      assert nil == MyHouseParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the calendar page", %{event: event} do
      assert "https://myhouseinthejunction.com/live-entertainment" ==
               MyHouseParser.details_url(event)
    end
  end
end
