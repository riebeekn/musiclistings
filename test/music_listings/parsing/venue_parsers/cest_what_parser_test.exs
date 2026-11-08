defmodule MusicListings.Parsing.VenueParsers.CestWhatParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.CestWhatParser

  setup do
    index_html = read_fixture("index.html")

    events = CestWhatParser.events(index_html)
    event = List.first(events)

    %{index_html: index_html, events: events, event: event}
  end

  defp read_fixture(name) do
    "#{File.cwd!()}/test/data/cest_what/#{name}"
    |> Path.expand()
    |> File.read!()
  end

  defp poster(alt, title) do
    ~s(<html><body><img src="poster.png" alt="#{alt}" title="#{title}"></body></html>)
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://cestwhat.com/" == CestWhatParser.source_url()
    end
  end

  describe "events/1" do
    test "returns the shows on the home page's poster", %{events: events} do
      assert [
               {~D[2026-11-07], ~T[20:00:00], "FOOL HEARTS"},
               {~D[2026-11-13], ~T[21:00:00], "HONEST LIARS"},
               {~D[2026-11-14], ~T[15:00:00], "HOT 5 JAZZMAKERS"},
               {~D[2026-11-20], ~T[20:00:00], "THE SEROTONES"},
               {~D[2026-11-21], ~T[20:00:00], "SUGARLESS DADDY"},
               {~D[2026-11-27], ~T[20:00:00], "REC LEAGUE"},
               {~D[2026-11-28], ~T[15:00:00], "HOT 5 JAZZMAKERS"},
               {~D[2026-11-28], ~T[20:00:00], "Y'ALLMAN BROTHERS"}
             ] == Enum.map(events, &{&1.date, &1.time, &1.title})
    end

    test "reads the October 2026 poster, whose month is only in its title" do
      body =
        poster(
          "c'est what! 02 FRI KILOWATT 8PM-11PM | PWYC 17 SAT HOT 5 JAZZMAKERS 3PM-6PM | PWYC " <>
            "WHAT'S UP? OCTOBER FOLLOWUS @CESTWHATTO",
          "What's Up October 2026"
        )

      assert [{~D[2026-10-02], "KILOWATT"}, {~D[2026-10-17], "HOT 5 JAZZMAKERS"}] ==
               body |> CestWhatParser.events() |> Enum.map(&{&1.date, &1.title})
    end

    test "reads the older month-first layout" do
      events = "april_poster.html" |> read_fixture() |> CestWhatParser.events()

      assert 7 == Enum.count(events)

      assert %{date: ~D[2026-04-10], time: ~T[21:00:00], title: "Honest Liars"} =
               List.first(events)

      # APR 11 Hot 5 Jazzmakers | 3-6pm -> 3pm
      assert ~T[15:00:00] == events |> Enum.at(1) |> CestWhatParser.event_time()
    end

    test "returns no events when the page has no poster" do
      assert [] == "C'EST WHAT MERCH SALE" |> poster("Merch") |> CestWhatParser.events()
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == CestWhatParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "cest_what_2026_11_07_20_00_00" == CestWhatParser.event_id(event)
    end

    test "gives shows on the same day their own ids", %{events: events} do
      ids = Enum.map(events, &CestWhatParser.event_id/1)

      assert ids == Enum.uniq(ids)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "cest_what_2026_11_07_20_00_00" == CestWhatParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "FOOL HEARTS" == CestWhatParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "FOOL HEARTS", openers: []} ==
               CestWhatParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-07] == CestWhatParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CestWhatParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == CestWhatParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns pay what you can", %{event: event} do
      assert %Price{format: :pwyc, hi: nil, lo: nil} == CestWhatParser.price(event)
    end

    test "returns unknown when the poster gives no price" do
      [event | _rest] = "april_poster.html" |> read_fixture() |> CestWhatParser.events()

      assert %Price{format: :unknown, hi: nil, lo: nil} == CestWhatParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CestWhatParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == CestWhatParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the home page", %{event: event} do
      assert "https://cestwhat.com/" == CestWhatParser.details_url(event)
    end
  end
end
