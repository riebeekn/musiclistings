defmodule MusicListings.Parsing.VenueParsers.ReservoirLoungeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.ReservoirLoungeParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/reservoir_lounge/index.csv")

    index_csv = File.read!(index_file_path)

    event =
      index_csv
      |> ReservoirLoungeParser.events()
      |> Enum.find(&(&1["band"] == "Shane Philips"))

    %{index_csv: index_csv, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://docs.google.com/spreadsheets/d/e/2PACX-1vTl2Egl9fk6KXx2FEngyFD-eClJ8WgPCzoOTrW9j6x5KVF9-zdpvJB_CVPHf7KBzuaVt303pzwuh7ki/pub?gid=206764270&single=true&output=csv" ==
               ReservoirLoungeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns an event for each night of the week", %{index_csv: index_csv} do
      events = ReservoirLoungeParser.events(index_csv)

      assert [
               ~D[2026-09-22],
               ~D[2026-09-23],
               ~D[2026-09-24],
               ~D[2026-09-25],
               ~D[2026-09-26],
               ~D[2026-09-27]
             ] == Enum.map(events, &ReservoirLoungeParser.event_date/1)
    end

    test "accepts rows already decoded by the http client", %{index_csv: index_csv} do
      rows = NimbleCSV.RFC4180.parse_string(index_csv, skip_headers: false)

      assert ReservoirLoungeParser.events(index_csv) == ReservoirLoungeParser.events(rows)
    end

    test "skips nights with nothing booked" do
      csv = """
      Week of,9/22/2026,,,
      Day,Artist,Genre,Time,Image
      Tuesday,,,,
      Wednesday,Alison Young,,9:00 pm,
      """

      assert [%{"band" => "Alison Young", "date" => ~D[2026-09-23]}] =
               ReservoirLoungeParser.events(csv)
    end

    test "returns no events when the week of date is not a tuesday" do
      csv = """
      Week of,2026-09-23,,,
      Day,Artist,Genre,Time,Image
      Tuesday,Janice Hagan,,9:00 pm,
      """

      assert [] == ReservoirLoungeParser.events(csv)
    end

    test "returns no events when the week of date is missing" do
      csv = """
      Day,Artist,Genre,Time,Image
      Tuesday,Janice Hagan,,9:00 pm,
      """

      assert [] == ReservoirLoungeParser.events(csv)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_csv: index_csv} do
      assert nil == ReservoirLoungeParser.next_page_url(index_csv, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "reservoir_lounge_2026_09_25" == ReservoirLoungeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "reservoir_lounge_2026_09_25" == ReservoirLoungeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Shane Philips" == ReservoirLoungeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Shane Philips",
               openers: []
             } == ReservoirLoungeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-09-25] == ReservoirLoungeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == ReservoirLoungeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:30:00] == ReservoirLoungeParser.event_time(event)
    end

    test "returns nil when no time is listed" do
      assert nil == ReservoirLoungeParser.event_time(%{"time" => ""})
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == ReservoirLoungeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == ReservoirLoungeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.reservoirlounge.com/contact.html#reserve" ==
               ReservoirLoungeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.reservoirlounge.com/schedule.html" ==
               ReservoirLoungeParser.details_url(event)
    end
  end
end
