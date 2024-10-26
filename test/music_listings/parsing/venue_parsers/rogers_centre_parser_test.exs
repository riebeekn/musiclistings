defmodule MusicListings.Parsing.VenueParsers.RogersCentreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.RogersCentreParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/rogers_centre/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/rogers_centre/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> RogersCentreParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.livenation.com/venue/KovZpa3Bbe/rogers-centre-events" ==
               RogersCentreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = RogersCentreParser.events(index_html)

      assert 10 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == RogersCentreParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "rogers_centre_2024_08_02_18_00_00" ==
               RogersCentreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "rogers_centre_2024_08_02_18_00_00" ==
               RogersCentreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Def Leppard / Journey: The Summer Stadium Tour with Cheap Trick" ==
               RogersCentreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Def Leppard",
               openers: ["Journey", "Cheap Trick"]
             } == RogersCentreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-02] == RogersCentreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == RogersCentreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[18:00:00] == RogersCentreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               RogersCentreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == RogersCentreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https://www.livenation.com/event/G5vZZ9z6yjKEU/def-leppard-journey-the-summer-stadium-tour-with-cheap-trick" ==
               RogersCentreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == RogersCentreParser.details_url(event)
    end
  end
end
