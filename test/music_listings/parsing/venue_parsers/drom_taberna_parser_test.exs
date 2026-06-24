defmodule MusicListings.Parsing.VenueParsers.DromTabernaParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DromTabernaParser

  setup do
    index_html =
      "#{File.cwd!()}/test/data/drom_taberna/index.html"
      |> Path.expand()
      |> File.read!()

    event =
      "#{File.cwd!()}/test/data/drom_taberna/single_event.html"
      |> Path.expand()
      |> File.read!()
      |> DromTabernaParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.dromtaberna.com/" == DromTabernaParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DromTabernaParser.events(index_html)

      assert 28 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil == DromTabernaParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "_events_james_margolis" == DromTabernaParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "_events_james_margolis" == DromTabernaParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "James Margolis" == DromTabernaParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: nil,
               openers: []
             } == DromTabernaParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2025-06-23] == DromTabernaParser.event_date(event)
    end

    test "returns the true calendar date for a pre-dawn event", %{index_html: index_html} do
      # Tamar Ilana is listed on Fri Jun 26 at 2:30am.  The parser records the
      # true calendar date - grouping it under the previous night is a listing
      # concern handled in MusicListings.Events.list_events/1.
      tamar_ilana =
        index_html
        |> DromTabernaParser.events()
        |> Enum.find(&(DromTabernaParser.event_title(&1) == "Tamar Ilana"))

      assert ~T[02:30:00] == DromTabernaParser.event_time(tamar_ilana)
      assert ~D[2025-06-26] == DromTabernaParser.event_date(tamar_ilana)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == DromTabernaParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[17:30:00] == DromTabernaParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :pwyc, lo: nil, hi: nil} ==
               DromTabernaParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == DromTabernaParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == DromTabernaParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.dromtaberna.com/events/james-margolis" ==
               DromTabernaParser.details_url(event)
    end
  end
end
