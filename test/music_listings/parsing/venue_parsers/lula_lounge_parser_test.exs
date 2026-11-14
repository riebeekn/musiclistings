defmodule MusicListings.Parsing.VenueParsers.LulaLoungeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.LulaLoungeParser

  setup do
    index_json =
      "#{File.cwd!()}/test/data/lula_lounge/index.json"
      |> Path.expand()
      |> File.read!()

    events = LulaLoungeParser.events(index_json)

    event = Enum.find(events, &(&1["id"] == "2002113624747"))

    %{index_json: index_json, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.lula.ca/calendar" == LulaLoungeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns the listed events", %{events: events} do
      assert 21 == Enum.count(events)
    end

    test "accepts an already decoded body", %{index_json: index_json} do
      assert 21 == index_json |> Jason.decode!() |> LulaLoungeParser.events() |> Enum.count()
    end

    test "skips events that aren't live, are unlisted or are online", %{event: event} do
      assert [] == LulaLoungeParser.events([%{event | "status" => "draft"}])
      assert [] == LulaLoungeParser.events([%{event | "listed" => false}])
      assert [] == LulaLoungeParser.events([%{event | "online_event" => true}])
    end

    test "returns no events for an unexpected body" do
      assert [] == LulaLoungeParser.events(%{"error" => "Unauthorized Session"})
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == LulaLoungeParser.next_page_url(index_json, nil)
    end
  end

  describe "event_id/1" do
    test "returns an id built from the eventbrite id", %{event: event} do
      assert "lula_lounge_2002113624747" == LulaLoungeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "lula_lounge_2002113624747" == LulaLoungeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns the event title with whitespace collapsed", %{event: event} do
      assert "Salsa Saturday w Adis Rodriguez + DJ Van Gogh + Baila Boogaloo!" ==
               LulaLoungeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Salsa Saturday w Adis Rodriguez + DJ Van Gogh + Baila Boogaloo!",
               openers: []
             } == LulaLoungeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-14] == LulaLoungeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns no additional dates", %{event: event} do
      assert [] == LulaLoungeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the local start time", %{event: event} do
      assert ~T[20:30:00] == LulaLoungeParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the cheapest paid ticket as a from price", %{event: event} do
      assert %Price{format: :variable, lo: Decimal.new("15.00"), hi: Decimal.new("15.00")} ==
               LulaLoungeParser.price(event)
    end

    test "ignores free tiers when there are paid tickets", %{events: events} do
      event = Enum.find(events, &(&1["id"] == "2004269413770"))

      assert %Price{format: :variable, lo: Decimal.new("15.00"), hi: Decimal.new("15.00")} ==
               LulaLoungeParser.price(event)
    end

    test "returns a fixed price for a single ticket price", %{events: events} do
      event = Enum.find(events, &(&1["id"] == "2004089646080"))

      assert %Price{format: :fixed, lo: Decimal.new("45.00"), hi: Decimal.new("45.00")} ==
               LulaLoungeParser.price(event)
    end

    test "returns free when every ticket is free", %{event: event} do
      event = %{event | "tickets" => [%{"free" => true, "cost" => nil}]}

      assert %Price{format: :free, lo: nil, hi: nil} == LulaLoungeParser.price(event)
    end

    test "returns unknown when there are no tickets", %{events: events} do
      event = Enum.find(events, &(&1["id"] == "1994229214263"))

      assert %Price{format: :unknown, lo: nil, hi: nil} == LulaLoungeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == LulaLoungeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the eventbrite url", %{event: event} do
      assert "https://www.eventbrite.ca/e/salsa-saturday-w-adis-rodriguez-dj-van-gogh-baila-boogaloo-tickets-2002113624747" ==
               LulaLoungeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the eventbrite url", %{event: event} do
      assert "https://www.eventbrite.ca/e/salsa-saturday-w-adis-rodriguez-dj-van-gogh-baila-boogaloo-tickets-2002113624747" ==
               LulaLoungeParser.details_url(event)
    end
  end
end
