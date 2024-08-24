defmodule MusicListings.Parsing.VenueParsers.BudweiserStageParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BudweiserStageParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/budweiser_stage/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/budweiser_stage/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> BudweiserStageParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events" ==
               BudweiserStageParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = BudweiserStageParser.events(index_html)

      assert 48 = Enum.count(events)
    end
  end

  describe "next_page_url/1" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == BudweiserStageParser.next_page_url(index_html)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "alanis_morissette_the_triple_moon_tour_2024_07_14" ==
               BudweiserStageParser.event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Alanis Morissette - The Triple Moon Tour" == BudweiserStageParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Alanis Morissette",
               openers: ["Joan Jett & the Blackhearts", "Morgan Wade"]
             } == BudweiserStageParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-07-14] == BudweiserStageParser.event_date(event)
    end
  end

  describe "event_end_date/1" do
    test "returns the final date of the event if a date range", %{event: event} do
      assert nil == BudweiserStageParser.event_end_date(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == BudweiserStageParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, lo: nil, hi: nil} ==
               BudweiserStageParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == BudweiserStageParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https:\/\/www.livenation.com\/event\/G5vZZ9UBGCvW_\/alanis-morissette-the-triple-moon-tour" ==
               BudweiserStageParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == BudweiserStageParser.details_url(event)
    end
  end
end
