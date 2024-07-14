defmodule MusicListings.Parsing.BudweiserStageParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.BudweiserStageParser
  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/budweiser_stage/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/budweiser_stage/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> BudweiserStageParser.event_selector()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.livenation.com/venue/KovZpZAEkkIA/budweiser-stage-events" ==
               BudweiserStageParser.source_url()
    end
  end

  describe "venue_name/0" do
    test "returns expected value" do
      assert "Budweiser Stage" == BudweiserStageParser.venue_name()
    end
  end

  describe "event_selector/1" do
    test "returns expected events", %{index_html: index_html} do
      events = BudweiserStageParser.event_selector(index_html)

      # should find 56 events
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
      assert "G5vZZ9UBGCvW_alanis-morissette-the-triple-moon-tour" ==
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

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[19:00:00] == BudweiserStageParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :tbd, lo: Decimal.new("0"), hi: Decimal.new("0")} ==
               BudweiserStageParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :tbd == BudweiserStageParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert "https:\/\/www.livenation.com\/event\/G5vZZ9UBGCvW_\/alanis-morissette-the-triple-moon-tour" ==
               BudweiserStageParser.ticket_url(event)
    end
  end
end
