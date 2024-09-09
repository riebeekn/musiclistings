defmodule MusicListings.Parsing.VenueParsers.LinsmoreParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.LinsmoreParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/linsmore/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/linsmore/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> LinsmoreParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.linsmoretavern.com/event-calendar/" == LinsmoreParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = LinsmoreParser.events(index_html)

      assert 30 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == LinsmoreParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "tcec-event-4786" == LinsmoreParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "tcec-event-4786" == LinsmoreParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Mike Sedgewick's Blues Revue & Open Jam Returns to the Linsmore Tavern in August!" ==
               LinsmoreParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner:
                 "Mike Sedgewick's Blues Revue & Open Jam Returns to the Linsmore Tavern in August!",
               openers: []
             } == LinsmoreParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-08-04] == LinsmoreParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == LinsmoreParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == LinsmoreParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               LinsmoreParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == LinsmoreParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == LinsmoreParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.linsmoretavern.com/tc-events/4786/" ==
               LinsmoreParser.details_url(event)
    end
  end
end
