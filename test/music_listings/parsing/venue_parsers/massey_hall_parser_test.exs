defmodule MusicListings.Parsing.VenueParsers.MasseyHallParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.MasseyHallParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/massey_hall/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/massey_hall/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> MasseyHallParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://masseyhall.mhrth.com/tickets/?page=1" == MasseyHallParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = MasseyHallParser.events(index_html)

      assert 12 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert "https://masseyhall.mhrth.com/tickets/?page=2" ==
               MasseyHallParser.next_page_url(
                 index_html,
                 "https://masseyhall.mhrth.com/tickets/?page=1"
               )

      assert "https://masseyhall.mhrth.com/tickets/?page=3" ==
               MasseyHallParser.next_page_url(
                 index_html,
                 "https://masseyhall.mhrth.com/tickets/?page=2"
               )

      assert "https://masseyhall.mhrth.com/tickets/?page=4" ==
               MasseyHallParser.next_page_url(
                 index_html,
                 "https://masseyhall.mhrth.com/tickets/?page=3"
               )

      assert "https://masseyhall.mhrth.com/tickets/?page=5" ==
               MasseyHallParser.next_page_url(
                 index_html,
                 "https://masseyhall.mhrth.com/tickets/?page=4"
               )

      assert nil ==
               MasseyHallParser.next_page_url(
                 index_html,
                 "https://masseyhall.mhrth.com/tickets/?page=5"
               )
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "jessie_reyez_2025_12_05" == MasseyHallParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "jessie_reyez_2025_12_05" == MasseyHallParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Jessie Reyez" == MasseyHallParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Jessie Reyez",
               openers: []
             } == MasseyHallParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-12-05] == MasseyHallParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [~D[2025-12-06]] == MasseyHallParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == MasseyHallParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               MasseyHallParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == MasseyHallParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == MasseyHallParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://masseyhall.mhrth.com/tickets/jessie-reyez/" ==
               MasseyHallParser.details_url(event)
    end
  end
end
