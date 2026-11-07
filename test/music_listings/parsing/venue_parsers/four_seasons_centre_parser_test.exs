defmodule MusicListings.Parsing.VenueParsers.FourSeasonsCentreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.FourSeasonsCentreParser

  setup do
    index_json =
      "#{File.cwd!()}/test/data/four_seasons_centre/index.json"
      |> Path.expand()
      |> File.read!()

    events = FourSeasonsCentreParser.events(index_json)

    event = Enum.find(events, &(&1["PerformanceNumber"] == 2539))

    %{index_json: index_json, events: events, event: event}
  end

  defp event_titled(events, title), do: Enum.find(events, &(&1["Title"] == title))

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://d1ndd0kfyiplr2.cloudfront.net/Prod/events/10/40/Live" ==
               FourSeasonsCentreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns a performance per event at the Four Seasons Centre", %{events: events} do
      assert 39 == Enum.count(events)

      titles = events |> Enum.map(&FourSeasonsCentreParser.event_title/1) |> Enum.uniq()

      assert [
               "The Turn of the Screw",
               "Ariadne auf Naxos",
               "Empire of Wild",
               "The Elixir of Love",
               "Under 25 Night: The Turn of the Screw" | _free_concerts
             ] = titles
    end

    test "includes the free concerts in its Richard Bradshaw Amphitheatre", %{events: events} do
      free_concerts =
        Enum.filter(events, &(&1["Venue"]["Title"] == "Richard Bradshaw Amphitheatre"))

      assert 10 == Enum.count(free_concerts)
      assert event_titled(events, "Winter in Paris")
    end

    test "skips productions at other venues", %{events: events} do
      refute event_titled(events, "Come Closer")
      refute event_titled(events, "COC @ Todmorden Mills")
    end

    test "skips productions the calendar flags as duplicates", %{events: events} do
      refute event_titled(events, "OperaNation")
    end

    test "skips rehearsals", %{events: events} do
      refute Enum.any?(events, &(&1["PerformanceNumber"] in [2630, 2631, 2695]))
    end

    test "has a unique id for each performance", %{events: events} do
      ids = Enum.map(events, &FourSeasonsCentreParser.event_id/1)

      assert ids == Enum.uniq(ids)
    end

    test "decodes an already decoded body", %{index_json: index_json} do
      assert 39 ==
               index_json |> Jason.decode!() |> FourSeasonsCentreParser.events() |> Enum.count()
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_json: index_json} do
      assert nil == FourSeasonsCentreParser.next_page_url(index_json, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "four_seasons_centre_574_2539" == FourSeasonsCentreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "four_seasons_centre_574_2539" == FourSeasonsCentreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Turn of the Screw" == FourSeasonsCentreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "The Turn of the Screw", openers: []} ==
               FourSeasonsCentreParser.performers(event)
    end

    test "returns a free concert's performers", %{events: events} do
      assert %Performers{headliner: "Hilario Durán, piano", openers: []} ==
               events
               |> event_titled("An Afternoon of Cuban Jazz")
               |> FourSeasonsCentreParser.performers()
    end
  end

  describe "event_date/1" do
    test "returns the performance date", %{event: event} do
      assert ~D[2027-01-23] == FourSeasonsCentreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns an empty list", %{event: event} do
      assert [] == FourSeasonsCentreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the performance's local time", %{event: event} do
      assert ~T[19:30:00] == FourSeasonsCentreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns an unknown price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} == FourSeasonsCentreParser.price(event)
    end

    test "returns free for a free concert", %{events: events} do
      assert %Price{format: :free, lo: nil, hi: nil} ==
               events
               |> event_titled("An Afternoon of Cuban Jazz")
               |> FourSeasonsCentreParser.price()
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == FourSeasonsCentreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the performance's page on the ticketing site", %{event: event} do
      assert "https://my.coc.ca/2538/2539" == FourSeasonsCentreParser.ticket_url(event)
    end

    test "returns the production's own booking link", %{events: events} do
      assert "https://my.coc.ca/2634/2635" ==
               events
               |> event_titled("Under 25 Night: The Turn of the Screw")
               |> FourSeasonsCentreParser.ticket_url()
    end

    test "returns nil when sold out", %{event: event} do
      assert nil == FourSeasonsCentreParser.ticket_url(%{event | "Availability" => 0})
    end
  end

  describe "details_url/1" do
    test "returns the production's page", %{event: event} do
      assert "https://www.coc.ca/tickets/2627-season/the-turn-of-the-screw" ==
               FourSeasonsCentreParser.details_url(event)
    end
  end
end
