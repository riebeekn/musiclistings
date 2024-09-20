defmodule MusicListings.Parsing.VenueParsers.GreatCanadianCasinoParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.GreatCanadianCasinoParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/great_canadian_casino/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/great_canadian_casino/single_event.json")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> GreatCanadianCasinoParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://api.greatcanadian.com/wp-json/snap_widgets_api/v1/entertainment?lang=en&property=23676" ==
               GreatCanadianCasinoParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = GreatCanadianCasinoParser.events(index_html)

      assert 19 == Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == GreatCanadianCasinoParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "frank_turner_presents_lost_evenings_vii_2024_09_19" ==
               GreatCanadianCasinoParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "frank_turner_presents_lost_evenings_vii_2024_09_19" ==
               GreatCanadianCasinoParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Frank Turner Presents Lost Evenings VII" ==
               GreatCanadianCasinoParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Frank Turner Presents Lost Evenings VII",
               openers: []
             } == GreatCanadianCasinoParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-19] == GreatCanadianCasinoParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [~D[2024-09-20], ~D[2024-09-21], ~D[2024-09-22]] ==
               GreatCanadianCasinoParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == GreatCanadianCasinoParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               GreatCanadianCasinoParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == GreatCanadianCasinoParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.ticketmaster.ca/the-theatre-at-great-canadian-casino-tickets-toronto/venue/132544" ==
               GreatCanadianCasinoParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://greatcanadian.com/event/lost-evenings/" ==
               GreatCanadianCasinoParser.details_url(event)
    end
  end
end
