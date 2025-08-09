defmodule MusicListings.Parsing.VenueParsers.SoundGarageParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.SoundGarageParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/sound_garage/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/sound_garage/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> SoundGarageParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://dice.fm/venue/the-sound-garage-xeval" == SoundGarageParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = SoundGarageParser.events(index_html)

      assert 18 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil as there's no pagination", %{index_html: index_html} do
      assert nil ==
               SoundGarageParser.next_page_url(
                 index_html,
                 "https://dice.fm/venue/the-sound-garage-xeval"
               )
    end
  end

  describe "event_id/1" do
    test "returns expected value", %{event: event} do
      assert "sound_garage_2025_08_16_19_00_00" == SoundGarageParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns the event id", %{event: event} do
      assert SoundGarageParser.event_id(event) == SoundGarageParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns expected value", %{event: event} do
      assert "Yuno" == SoundGarageParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns expected value", %{event: event} do
      assert Performers.new(["Yuno"]) == SoundGarageParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns expected value", %{event: event} do
      assert ~D[2025-08-16] == SoundGarageParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns empty list", %{event: event} do
      assert [] == SoundGarageParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns expected value", %{event: event} do
      assert ~T[19:00:00] == SoundGarageParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns unknown price", %{event: event} do
      assert Price.unknown() == SoundGarageParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns unknown", %{event: event} do
      assert :unknown == SoundGarageParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns expected value", %{event: event} do
      assert "https://dice.fm/event/bbdv7v-yuno-16th-aug-the-sound-garage-toronto-tickets" ==
               SoundGarageParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns expected value", %{event: event} do
      assert nil == SoundGarageParser.details_url(event)
    end
  end
end
