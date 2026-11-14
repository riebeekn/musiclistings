defmodule MusicListings.Parsing.VenueParsers.HirutParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.HirutParser

  setup do
    index_json =
      "#{File.cwd!()}/test/data/hirut/index.json"
      |> Path.expand()
      |> File.read!()

    events = HirutParser.events(index_json)

    event = Enum.find(events, &(&1["startDate"] == "2026-11-19"))

    %{index_json: index_json, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.hirutjazz.ca/copy-of-live-shows" == HirutParser.source_url()
    end
  end

  describe "events/1" do
    test "returns the events, skipping comedy, closed and restaurant only nights", %{
      events: events
    } do
      assert 43 == Enum.count(events)

      titles = Enum.map(events, &HirutParser.event_title/1)

      refute "Hirut Hoot" in titles
      refute "Closed Today" in titles
      refute "Restaurant Open" in titles
    end

    test "accepts an already decoded body", %{index_json: index_json} do
      assert 43 == index_json |> Jason.decode!() |> HirutParser.events() |> Enum.count()
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == HirutParser.next_page_url(index_json, nil)
    end
  end

  describe "event_id/1" do
    test "returns an id built from the venue and date", %{event: event} do
      assert "hirut_2026_11_19" == HirutParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "hirut_2026_11_19" == HirutParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns the event title", %{event: event} do
      assert "Mark Eisenman Quartet" == HirutParser.event_title(event)
    end

    test "strips surrounding quotes and whitespace", %{event: event} do
      assert "Veterans & Upstarts" ==
               HirutParser.event_title(%{event | "title" => " \"Veterans & Upstarts\" "})
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Mark Eisenman Quartet", openers: []} ==
               HirutParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-19] == HirutParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns no additional dates", %{event: event} do
      assert [] == HirutParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == HirutParser.event_time(event)
    end

    test "returns nil for an all day event", %{event: event} do
      assert nil == event |> Map.put("allday", true) |> HirutParser.event_time()
    end
  end

  describe "price/1" do
    test "returns the cover charge from the description", %{event: event} do
      assert %Price{format: :fixed, lo: Decimal.new("20"), hi: Decimal.new("20")} ==
               HirutParser.price(event)
    end

    test "returns the first price when several are listed", %{events: events} do
      event = Enum.find(events, &(&1["startDate"] == "2026-11-22"))

      assert %Price{format: :fixed, lo: Decimal.new("20"), hi: Decimal.new("20")} ==
               HirutParser.price(event)
    end

    test "returns unknown when there's no price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               HirutParser.price(%{event | "description" => "No cover"})
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == HirutParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns nil", %{event: event} do
      assert nil == HirutParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the calendar page", %{event: event} do
      assert "https://www.hirutjazz.ca/copy-of-live-shows" == HirutParser.details_url(event)
    end
  end
end
