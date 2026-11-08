defmodule MusicListings.Parsing.VenueParsers.DukeLiveParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DukeLiveParser

  setup do
    index_json =
      "#{File.cwd!()}/test/data/duke_live/index.json"
      |> Path.expand()
      |> File.read!()

    events = DukeLiveParser.events(index_json)

    event = Enum.find(events, &(&1["id"] == "2004429790461"))

    %{index_json: index_json, events: events, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://dukelive.ca/api/events" == DukeLiveParser.source_url()
    end
  end

  describe "events/1" do
    test "returns the events, skipping karaoke nights", %{events: events} do
      assert ["Megacity Big Band", "NEWSAPALOOZA", "Advocats Big Band"] ==
               Enum.map(events, &DukeLiveParser.event_title/1)
    end

    test "accepts an already decoded body", %{index_json: index_json} do
      assert 3 == index_json |> Jason.decode!() |> DukeLiveParser.events() |> Enum.count()
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == DukeLiveParser.next_page_url(index_json, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "duke_live_2004429790461" == DukeLiveParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "duke_live_2004429790461" == DukeLiveParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "strips the presented by suffix", %{event: event} do
      assert "Megacity Big Band" == DukeLiveParser.event_title(event)
    end

    test "strips the presented by suffix whatever its case or punctuation", %{event: event} do
      for name <- [
            "Advocats Big Band Presented by: The Duke Live",
            "NEWSAPALOOZA Presented By The Duke Live"
          ] do
        event = put_in(event, ["name", "text"], name)

        refute DukeLiveParser.event_title(event) =~ ~r/presented/i
      end
    end

    test "leaves other titles alone", %{event: event} do
      event = put_in(event, ["name", "text"], "The Weekend Blues Band")

      assert "The Weekend Blues Band" == DukeLiveParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "Megacity Big Band", openers: []} ==
               DukeLiveParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-11-08] == DukeLiveParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns no additional dates", %{event: event} do
      assert [] == DukeLiveParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[17:00:00] == DukeLiveParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns unknown for a paid event", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} == DukeLiveParser.price(event)
    end

    test "returns free for a free event", %{event: event} do
      assert %Price{format: :free, lo: nil, hi: nil} ==
               DukeLiveParser.price(%{event | "is_free" => true})
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == DukeLiveParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the eventbrite url", %{event: event} do
      assert "https://www.eventbrite.ca/e/megacity-big-band-presented-by-the-duke-live-tickets-2004429790461" ==
               DukeLiveParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the eventbrite url", %{event: event} do
      assert "https://www.eventbrite.ca/e/megacity-big-band-presented-by-the-duke-live-tickets-2004429790461" ==
               DukeLiveParser.details_url(event)
    end
  end
end
