defmodule MusicListings.Parsing.VenueParsers.DrumsNFlatsParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DrumsNFlatsParser

  # The listing has no year, so it's inferred relative to the test env's mock
  # date of 2024-08-01, making these shows 2024 dates.
  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/drums_n_flats/index.html")
    index_html = File.read!(index_file_path)

    events = DrumsNFlatsParser.events(index_html)
    event = List.first(events)

    %{index_html: index_html, events: events, event: event}
  end

  defp event_titled(events, title), do: Enum.find(events, &(&1.title == title))

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.drumsnflats.com/events/live-music/" == DrumsNFlatsParser.source_url()
    end
  end

  describe "events/1" do
    test "returns one event per show line, skipping headings and TBD dates", %{events: events} do
      assert 20 == Enum.count(events)
      refute Enum.any?(events, &(&1.title =~ ~r/tbd|november|best sports bar/i))
    end

    test "has a unique id for each show", %{events: events} do
      ids = Enum.map(events, &DrumsNFlatsParser.event_id/1)

      assert ids == Enum.uniq(ids)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == DrumsNFlatsParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "drums_n_flats_2024_10_23_21_00_00" == DrumsNFlatsParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "drums_n_flats_2024_10_23_21_00_00" == DrumsNFlatsParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns the title without the date or price", %{event: event} do
      assert "WE PLAY DISCO!" == DrumsNFlatsParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{headliner: "WE PLAY DISCO!", openers: []} ==
               DrumsNFlatsParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "reads Rocktober as October", %{event: event} do
      assert ~D[2024-10-23] == DrumsNFlatsParser.event_date(event)
    end

    test "uses the month and day when the weekday is wrong", %{events: events} do
      # listed as "Thursday November 20"
      event = event_titled(events, "THE GARDEN")

      assert ~D[2024-11-20] == DrumsNFlatsParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == DrumsNFlatsParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event time", %{event: event} do
      assert ~T[21:00:00] == DrumsNFlatsParser.event_time(event)
    end

    test "returns an earlier time when listed", %{events: events} do
      event = event_titled(events, "PRETZEL LOGIC tribute to STEELY DAN")

      assert ~T[20:00:00] == DrumsNFlatsParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the ticket price", %{event: event} do
      assert %Price{format: :fixed, lo: Decimal.new("15"), hi: Decimal.new("15")} ==
               DrumsNFlatsParser.price(event)
    end

    test "returns the cover charge", %{events: events} do
      event = event_titled(events, "NORTH OF 7")

      assert %Price{format: :fixed, lo: Decimal.new("10"), hi: Decimal.new("10")} ==
               DrumsNFlatsParser.price(event)
    end

    test "returns a range for advance and door prices", %{events: events} do
      event = event_titled(events, "RUDE E BONES")

      assert %Price{format: :range, lo: Decimal.new("10"), hi: Decimal.new("15")} ==
               DrumsNFlatsParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == DrumsNFlatsParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == DrumsNFlatsParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the live music page", %{event: event} do
      assert "https://www.drumsnflats.com/events/live-music/" ==
               DrumsNFlatsParser.details_url(event)
    end
  end
end
