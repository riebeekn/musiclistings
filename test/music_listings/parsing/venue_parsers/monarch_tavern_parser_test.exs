defmodule MusicListings.Parsing.VenueParsers.MonarchTavernParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MonarchTavernParser

  setup do
    index_json =
      "#{File.cwd!()}/test/data/monarch_tavern/index.json"
      |> Path.expand()
      |> File.read!()

    events = MonarchTavernParser.events(index_json)

    event = Enum.find(events, &(&1["slug"] == "dabda-2026-11-21"))

    %{index_json: index_json, events: events, event: event}
  end

  describe "source_url/0" do
    test "queries the published downstairs events from today on" do
      uri = URI.parse(MonarchTavernParser.source_url())

      assert "https://ffejqqqltnseiytktcmy.supabase.co/rest/v1/events" ==
               "#{uri.scheme}://#{uri.host}#{uri.path}"

      query = URI.decode_query(uri.query)

      assert "eq.downstairs" == query["venue"]
      assert "eq.published" == query["status"]
      assert "gte.2024-08-01" == query["start_at"]
      assert "start_at.asc" == query["order"]
    end
  end

  describe "events/1" do
    test "returns the downstairs events, skipping blank titles", %{events: events} do
      assert [
               "James Ivy",
               "Whitney Smith Big Steam Band",
               "Doom Scroll, the You & Me’s, and Big Brother",
               "Cherry Garcia Band, Tell It To Sweeney",
               "Dabda",
               "Soledad Brothers, Ichi-Bons"
             ] == Enum.map(events, &MonarchTavernParser.event_title/1)
    end

    test "skips a title with no letters or digits", %{event: event} do
      assert [] == MonarchTavernParser.events([%{event | "title" => "@"}])
    end

    test "accepts an already decoded body", %{index_json: index_json} do
      assert 6 == index_json |> Jason.decode!() |> MonarchTavernParser.events() |> Enum.count()
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == MonarchTavernParser.next_page_url(index_json, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "monarch_tavern_5b830084-71fe-4857-b147-41a1efb5578c" ==
               MonarchTavernParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "monarch_tavern_5b830084-71fe-4857-b147-41a1efb5578c" ==
               MonarchTavernParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns the event title", %{event: event} do
      assert "Dabda" == MonarchTavernParser.event_title(event)
    end

    test "strips a trailing 'at the Monarch Tavern'", %{event: event} do
      for title <- ["Hot Freaks at the Monarch Tavern", "Hot Freaks at Monarch", "Hot Freaks"] do
        assert "Hot Freaks" == MonarchTavernParser.event_title(%{event | "title" => title})
      end
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Dabda", openers: []} ==
               MonarchTavernParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date in Toronto", %{event: event} do
      # start_at is 2026-11-22T01:00:00Z
      assert ~D[2026-11-21] == MonarchTavernParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns no additional dates", %{event: event} do
      assert [] == MonarchTavernParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event time in Toronto", %{event: event} do
      assert ~T[20:00:00] == MonarchTavernParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns unknown", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} == MonarchTavernParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns 19+ when the description says so", %{events: events} do
      event = Enum.find(events, &(&1["slug"] == "soledad-brothers-ichi-bons-2026-12-04"))

      assert :nineteen_plus == MonarchTavernParser.age_restriction(event)
    end

    test "returns all ages when the description says so", %{event: event} do
      assert :all_ages ==
               MonarchTavernParser.age_restriction(%{event | "description" => "An all-ages show"})
    end

    test "returns unknown otherwise", %{event: event} do
      assert :unknown == MonarchTavernParser.age_restriction(%{event | "description" => ""})
      assert :unknown == MonarchTavernParser.age_restriction(%{event | "description" => nil})
    end
  end

  describe "ticket_url/1" do
    test "returns the ticket url", %{event: event} do
      assert "https://dice.fm/event/6aa42b646b03960001547a69" ==
               MonarchTavernParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event's page on the venue site", %{event: event} do
      assert "https://www.themonarchtavern.com/events/dabda-2026-11-21" ==
               MonarchTavernParser.details_url(event)
    end
  end
end
