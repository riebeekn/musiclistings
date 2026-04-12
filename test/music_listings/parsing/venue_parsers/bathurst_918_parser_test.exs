defmodule MusicListings.Parsing.VenueParsers.Bathurst918ParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.Bathurst918Parser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/bathurst_918/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/bathurst_918/single_event.json")

    index_body = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> Bathurst918Parser.events()
      |> List.first()

    %{index_body: index_body, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://partners-endpoint.dice.fm/api/v2/events?page%5Bsize%5D=24&types=linkout%2Cevent&filter%5Bvenues%5D%5B%5D=918+Bathurst+Centre&filter%5Bflags%5D%5B%5D=going_ahead&filter%5Bflags%5D%5B%5D=rescheduled" ==
               Bathurst918Parser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_body: index_body} do
      events = Bathurst918Parser.events(index_body)
      assert 1 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_body: index_body} do
      assert nil ==
               Bathurst918Parser.next_page_url(
                 index_body,
                 "https://partners-endpoint.dice.fm/api/v2/events"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "918_bathurst_centre_695f2bef3dd34700019fcf79" ==
               Bathurst918Parser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "918_bathurst_centre_695f2bef3dd34700019fcf79" ==
               Bathurst918Parser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "The Messthetics and James Brandon Lewis" == Bathurst918Parser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "The Messthetics",
               openers: ["James Brandon Lewis"]
             } == Bathurst918Parser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2026-05-02] == Bathurst918Parser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == Bathurst918Parser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == Bathurst918Parser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :fixed, lo: Decimal.new("26.55"), hi: Decimal.new("26.55")} ==
               Bathurst918Parser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :all_ages == Bathurst918Parser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://link.dice.fm/Y2c1374a5b0d" == Bathurst918Parser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://link.dice.fm/Y2c1374a5b0d" == Bathurst918Parser.details_url(event)
    end
  end
end
