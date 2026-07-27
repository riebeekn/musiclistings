defmodule MusicListings.Parsing.VenueParsers.ContxtByTraneParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ContxtByTraneParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/contxt_by_trane/index.json")
    index_json = File.read!(index_file_path)

    events = ContxtByTraneParser.events(index_json)

    %{
      index_json: index_json,
      events: events,
      event: event_with_id(events, "76r15aj84hibv8osbe79bfo2un")
    }
  end

  defp event_with_id(events, id), do: Enum.find(events, &(&1["id"] == id))

  defp titles(events), do: Enum.map(events, &ContxtByTraneParser.event_title/1)

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.googleapis.com/calendar/v3/calendars/027559b208d0dc7e88f4b87e13bd762b0186c7a96b5521284a8786c0ec36d49c%40group.calendar.google.com/events?key=AIzaSyDOtGM5jr8bNp1utVpG2_gSRH03RNGBkI8&singleEvents=true&orderBy=startTime&maxResults=250&timeZone=America/Toronto&timeMin=2024-08-01T00:00:00Z" ==
               ContxtByTraneParser.source_url()
    end
  end

  describe "retrieve_events_fun/0" do
    test "pulls the calendar feed" do
      assert {:ok, %Response{status: 200, body: body}} =
               ContxtByTraneParser.retrieve_events_fun().(ContxtByTraneParser.source_url())

      assert 10 = body |> ContxtByTraneParser.events() |> Enum.count()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 10 = Enum.count(events)
    end

    test "drops entries that are not shows", %{events: events} do
      titles = titles(events)

      refute "Dining" in titles
      refute "Private Event" in titles
      refute "Brunch in CONTXT" in titles
      refute "Film Night - Superfly" in titles
    end

    test "drops shows held at other venues", %{events: events} do
      titles = titles(events)

      # off site per the title
      refute "The Sade Experience at 918 Bathurst" in titles

      # off site per the location, which the title doesn't mention
      refute ~s(Alex Harding & Lucian Ban - "DARK BLUE" Toronto Release Concert) in titles
    end

    test "keeps meals that bill a performer", %{events: events} do
      assert "Lunch with Muneeb Hermans Quartet" in titles(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil when the feed has no further pages", %{index_json: index_json} do
      assert nil ==
               ContxtByTraneParser.next_page_url(index_json, ContxtByTraneParser.source_url())
    end

    test "returns the current url with the page token when there is one" do
      body = Jason.encode!(%{"items" => [], "nextPageToken" => "token123"})

      assert "https://www.googleapis.com/calendar/v3/events?maxResults=250&pageToken=token123" ==
               ContxtByTraneParser.next_page_url(
                 body,
                 "https://www.googleapis.com/calendar/v3/events?maxResults=250"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "76r15aj84hibv8osbe79bfo2un" == ContxtByTraneParser.event_id(event)
    end

    test "returns a per date id for recurring events", %{events: events} do
      event = event_with_id(events, "nj4p3o8tqprlo88ulbl3e1jlea_20260709")

      assert "nj4p3o8tqprlo88ulbl3e1jlea_20260709" == ContxtByTraneParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "76r15aj84hibv8osbe79bfo2un" == ContxtByTraneParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title with the time prefix stripped", %{event: event} do
      assert "Teiku feat. Jason Stein and Jaribu Shahid" ==
               ContxtByTraneParser.event_title(event)
    end

    test "strips the assorted time prefix formats", %{events: events} do
      assert "The ROCKSTEADY and SOUL Listening and Dance Sessions" ==
               events
               |> event_with_id("nfvgohtvdb1kbktbo3advhv0rn")
               |> ContxtByTraneParser.event_title()

      assert "Sonny Rollins Tribute" ==
               events
               |> event_with_id("6mgc92fgs6n4010on4ch9unob9_20260808")
               |> ContxtByTraneParser.event_title()

      assert "Listening Room" ==
               events
               |> event_with_id("18iu1r19g7hc115i6mqsp771ke")
               |> ContxtByTraneParser.event_title()
    end

    test "leaves a title without a time prefix alone", %{events: events} do
      assert "The Mark Hundevad Quartet" ==
               events
               |> event_with_id("6ohv371gg8c963r4jvaarmndv3")
               |> ContxtByTraneParser.event_title()
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Teiku feat. Jason Stein and Jaribu Shahid",
               openers: []
             } == ContxtByTraneParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-07-04] == ContxtByTraneParser.event_date(event)
    end

    test "returns the event date for the rare timed event", %{index_json: index_json} do
      event =
        index_json
        |> Jason.decode!()
        |> Map.fetch!("items")
        |> Enum.find(&(&1["id"] == "6e45vma3m84lcob4n4ssm5j1i8"))

      assert ~D[2026-06-18] == ContxtByTraneParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == ContxtByTraneParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == ContxtByTraneParser.event_time(event)
    end

    test "returns the start time for the assorted time prefix formats", %{events: events} do
      # "7:30pm ..."
      assert ~T[19:30:00] ==
               events
               |> event_with_id("nfvgohtvdb1kbktbo3advhv0rn")
               |> ContxtByTraneParser.event_time()

      # "1:30pm ..."
      assert ~T[13:30:00] ==
               events
               |> event_with_id("6f47fjq6gsodm01n7o0ij7vvlk")
               |> ContxtByTraneParser.event_time()

      # "7pm - ..."
      assert ~T[19:00:00] ==
               events
               |> event_with_id("6mgc92fgs6n4010on4ch9unob9_20260808")
               |> ContxtByTraneParser.event_time()

      # "1-4pm ..." - the meridiem comes off the end of the range
      assert ~T[13:00:00] ==
               events
               |> event_with_id("18iu1r19g7hc115i6mqsp771ke")
               |> ContxtByTraneParser.event_time()
    end

    test "returns nil when the title carries no time", %{events: events} do
      assert nil ==
               events
               |> event_with_id("6ohv371gg8c963r4jvaarmndv3")
               |> ContxtByTraneParser.event_time()
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} == ContxtByTraneParser.price(event)
    end

    test "returns a pwyc price when the event says so", %{events: events} do
      event = event_with_id(events, "nj4p3o8tqprlo88ulbl3e1jlea_20260709")

      assert %Price{format: :pwyc, lo: nil, hi: nil} == ContxtByTraneParser.price(event)
    end

    test "returns a free price when the event says so", %{events: events} do
      event = event_with_id(events, "3v77qui28977lop7pqk04r1q7n")

      assert %Price{format: :free, lo: nil, hi: nil} == ContxtByTraneParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ContxtByTraneParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the ticket url unwrapped from google's redirector", %{event: event} do
      assert "https://tickets.contxtbytrane.com/events/contxtbytrane/2203887" ==
               ContxtByTraneParser.ticket_url(event)
    end

    test "skips links that aren't ticket links", %{events: events} do
      # description leads with a link to the band's own site
      assert "https://square.link/u/vZIYGHQl" ==
               events
               |> event_with_id("6eqm16et5sc5vobu87vlkckhrj")
               |> ContxtByTraneParser.ticket_url()
    end

    test "returns nil when there is no description", %{events: events} do
      assert nil ==
               events
               |> event_with_id("0rludm1rckacs20f4mtuuaqigr_20260607")
               |> ContxtByTraneParser.ticket_url()
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://tickets.contxtbytrane.com/events/contxtbytrane/2203887" ==
               ContxtByTraneParser.details_url(event)
    end

    test "falls back to the venue site", %{events: events} do
      assert "https://contxtbytrane.com/" ==
               events
               |> event_with_id("0rludm1rckacs20f4mtuuaqigr_20260607")
               |> ContxtByTraneParser.details_url()
    end
  end
end
