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
      assert "https://www.bloodbrothersbrewing.com/pages/the-sound-garage-165-geary-ave" ==
               SoundGarageParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = SoundGarageParser.events(index_html)

      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil as there's no pagination", %{index_html: index_html} do
      assert nil ==
               SoundGarageParser.next_page_url(
                 index_html,
                 "https://www.bloodbrothersbrewing.com/pages/the-sound-garage-165-geary-ave"
               )
    end
  end

  describe "event_id/1" do
    test "returns expected value", %{event: event} do
      assert "sound_garage_2025_05_14" == SoundGarageParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns the event id", %{event: event} do
      assert SoundGarageParser.event_id(event) == SoundGarageParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns expected value", %{event: event} do
      assert "Kerosene Heights w/ Hi, Low & Heavy Sweater" ==
               SoundGarageParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns expected value", %{event: event} do
      assert Performers.new(["Kerosene Heights w/ Hi, Low & Heavy Sweater"]) ==
               SoundGarageParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns expected value", %{event: event} do
      assert ~D[2025-05-14] == SoundGarageParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns empty list", %{event: event} do
      assert [] == SoundGarageParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns nil", %{event: event} do
      assert nil == SoundGarageParser.event_time(event)
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
      assert "https://www.tixr.com/groups/noisemakerpresents/events/kerosene-heights-171874" ==
               SoundGarageParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns expected value", %{event: event} do
      assert nil == SoundGarageParser.details_url(event)
    end
  end
end
