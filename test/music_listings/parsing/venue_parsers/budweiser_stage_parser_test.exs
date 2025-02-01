defmodule MusicListings.Parsing.VenueParsers.BudweiserStageParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.BudweiserStageParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/budweiser_stage/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/budweiser_stage/single_event.json")

    index_html = File.read!(index_file_path) |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://api.livenation.com/graphql" == BudweiserStageParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = BudweiserStageParser.events(index_html)

      assert 27 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == BudweiserStageParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "1AvZZb3Gkz0k9eI" ==
               BudweiserStageParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "1AvZZb3Gkz0k9eI" ==
               BudweiserStageParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Sessanta V 2.0: Primus, Puscifer, A Perfect Circle" ==
               BudweiserStageParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Sessanta",
               openers: ["Primus", "Puscifer", "A Perfect Circle"]
             } == BudweiserStageParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-05-22] == BudweiserStageParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == BudweiserStageParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == BudweiserStageParser.event_time(event)
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
      assert "https://www.ticketmaster.ca/sessanta-v-20-primus-puscifer-a-toronto-ontario-05-22-2025/event/1000612E241970A8" ==
               BudweiserStageParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert nil == BudweiserStageParser.details_url(event)
    end
  end
end
