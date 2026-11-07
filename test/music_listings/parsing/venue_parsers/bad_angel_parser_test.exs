defmodule MusicListings.Parsing.VenueParsers.BadAngelParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BadAngelParser

  setup do
    music_html =
      "#{File.cwd!()}/test/data/bad_angel/music.html"
      |> Path.expand()
      |> File.read!()

    events = BadAngelParser.events(music_html)

    %{music_html: music_html, events: events, event: List.first(events)}
  end

  defp event_titled(events, title), do: Enum.find(events, &(&1.title == title))

  # A minimal month's page, for the shapes the fixture doesn't cover
  defp month_page(title, body) do
    "<html><head><title>#{title}</title></head><body><div>#{body}</div></body></html>"
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.badangelbar.com/" == BadAngelParser.source_url()
    end
  end

  describe "retrieve_events_fun/0" do
    test "follows the home page's music link to the month's page", %{music_html: music_html} do
      assert {:ok, %Response{status: 200, body: ^music_html}} =
               BadAngelParser.retrieve_events_fun().(BadAngelParser.source_url())
    end
  end

  describe "events/1" do
    test "returns one event per dated show, skipping weekly series", %{events: events} do
      assert 20 == Enum.count(events)
      refute Enum.any?(events, &(&1.title =~ ~r/jared higgins|open stage|jam/i))
    end

    test "has a unique id for each show", %{events: events} do
      ids = Enum.map(events, &BadAngelParser.event_id/1)

      assert ids == Enum.uniq(ids)
    end

    test "takes the series' time from a paragraph after its heading", %{events: events} do
      assert %{date: ~D[2026-11-06], time: ~T[17:30:00]} = event_titled(events, "Max De Groot")
    end

    test "takes a show's inline time over the series' and drops it from the title", %{
      events: events
    } do
      assert %{date: ~D[2026-11-07], time: ~T[16:30:00]} = event_titled(events, "Julian Fauth")
    end

    test "decodes entities in the title", %{events: events} do
      assert event_titled(events, "SeaScape: Olivia Franco + André Valério")
    end

    test "puts a show across the new year in the next year" do
      html =
        month_page(
          "Bad Angel Music December 2026",
          "<h2>Sundays</h2><h3>Jazz: 8pm</h3><p>December 27 - A</p><p>January 3 - B</p>"
        )

      assert [%{date: ~D[2026-12-27]}, %{date: ~D[2027-01-03]}] = BadAngelParser.events(html)
    end

    test "reads a range ending in pm that starts in the morning as am" do
      html =
        month_page(
          "Bad Angel Music December 2026",
          "<h2>Sundays</h2><h3>Brunch:<br/>11-2pm</h3><p>December 6 - A</p>"
        )

      assert [%{time: ~T[11:00:00]}] = BadAngelParser.events(html)
    end

    test "doesn't take a price for a time" do
      html =
        month_page(
          "Bad Angel Music December 2026",
          "<h2>Mondays</h2><h3>Songwriters</h3><p><em>Seats are $15 (cash)</em></p><p>December 7 - A</p>"
        )

      assert [%{time: nil}] = BadAngelParser.events(html)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{music_html: music_html} do
      assert nil == BadAngelParser.next_page_url(music_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "bad_angel_2026_11_01_16_00_00" == BadAngelParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "bad_angel_2026_11_01_16_00_00" == BadAngelParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Wade Pollesel Trio" == BadAngelParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Wade Pollesel Trio", openers: []} ==
               BadAngelParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-01] == BadAngelParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns an empty list", %{event: event} do
      assert [] == BadAngelParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the series' start time", %{event: event} do
      assert ~T[16:00:00] == BadAngelParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns an unknown price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} == BadAngelParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == BadAngelParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns nil", %{event: event} do
      assert nil == BadAngelParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the home page", %{event: event} do
      assert "https://www.badangelbar.com/" == BadAngelParser.details_url(event)
    end
  end
end
