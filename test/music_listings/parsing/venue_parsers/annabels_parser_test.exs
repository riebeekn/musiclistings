defmodule MusicListings.Parsing.VenueParsers.AnnabelsParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.AnnabelsParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/annabels/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/annabels/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://gateway.admitone.com/embed/live-events?venueId=644bf7abee86fe5385227413&order=asc" ==
               AnnabelsParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = AnnabelsParser.events(index_html)

      assert 11 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == AnnabelsParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "annabels_2024_11_10_18_30_00" == AnnabelsParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "annabels_2024_11_10_18_30_00" == AnnabelsParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Norma Jean" == AnnabelsParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Norma Jean",
               openers: []
             } == AnnabelsParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-11-10] == AnnabelsParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == AnnabelsParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:30:00] == AnnabelsParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :fixed, hi: Decimal.new("35.00"), lo: Decimal.new("35.00")} ==
               AnnabelsParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :nineteen_plus == AnnabelsParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://admitone.com/events/norma-jean-toronto-9597535" ==
               AnnabelsParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == AnnabelsParser.details_url(event)
    end
  end
end
