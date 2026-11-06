defmodule MusicListings.Parsing.VenueParsers.NoonansParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.NoonansParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/noonans/index.html")
    index_html = File.read!(index_file_path)

    events = NoonansParser.events(index_html)
    event = List.first(events)

    %{index_html: index_html, events: events, event: event}
  end

  defp find_event(events, date, title) do
    Enum.find(events, &(&1["date"] == date and &1["title"] == title))
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://noonanspub.ca/events_refresh.php" == NoonansParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{events: events} do
      assert 98 == Enum.count(events)
    end

    test "groups each event under its date", %{events: events} do
      assert ["Beatles Sing-a-long", "Mark T Band"] ==
               events
               |> Enum.filter(&(&1["date"] == "Saturday November 14th"))
               |> Enum.map(& &1["title"])
    end

    test "has a unique id for each event", %{events: events} do
      ids = Enum.map(events, &NoonansParser.event_id/1)

      assert ids == Enum.uniq(ids)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == NoonansParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "the_circumstantialists_2024_11_06" == NoonansParser.event_id(event)
    end

    test "differs for events sharing a start time", %{events: events} do
      trivia = find_event(events, "Wednesday December 23rd", "Almost Jeopardy Trivia")
      irish_music = find_event(events, "Wednesday December 23rd", "Traditional Irish Music")

      assert NoonansParser.event_time(trivia) == NoonansParser.event_time(irish_music)
      assert NoonansParser.event_id(trivia) != NoonansParser.event_id(irish_music)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "the_circumstantialists_2024_11_06" == NoonansParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Circumstantialists" == NoonansParser.event_title(event)
    end

    test "decodes html entities", %{events: events} do
      assert find_event(events, "Saturday November 7th", "The Del Fi's")
      assert find_event(events, "Thursday November 12th", "Mock & Hilts")
    end

    test "normalizes apostrophes and trims whitespace", %{events: events} do
      assert find_event(events, "Tuesday November 17th", "Stuart Laughton's Radio Dial")
    end

    test "keeps a hyphen that is part of the title", %{events: events} do
      assert find_event(
               events,
               "Thursday November 26th",
               "Kim Stockwood and friends - all the covers you know and love"
             )

      assert find_event(events, "Friday February 19th", "9-volt Delight")
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Circumstantialists",
               openers: []
             } == NoonansParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-11-06] == NoonansParser.event_date(event)
    end

    test "rolls events early in the year into the next year", %{events: events} do
      event = find_event(events, "Saturday January 9th", "Mark T Band")

      assert ~D[2025-01-09] == NoonansParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == NoonansParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == NoonansParser.event_time(event)
    end

    test "returns nil for an event with no time", %{events: events} do
      event = find_event(events, "Thursday December 3rd", "Fitzgerald Family Christmas")

      assert nil == NoonansParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == NoonansParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == NoonansParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == NoonansParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://noonanspub.ca/" == NoonansParser.details_url(event)
    end
  end
end
