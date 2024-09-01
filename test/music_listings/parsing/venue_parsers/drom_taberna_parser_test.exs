defmodule MusicListings.Parsing.VenueParsers.DromTabernaParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.DromTabernaParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/drom_taberna/index.json")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/drom_taberna/single_event.json")

    index_html = index_file_path |> File.read!() |> Jason.decode!()

    event =
      single_event_file_path
      |> File.read!()
      |> Jason.decode!()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.dromtaberna.com/api/open/GetItemsByMonth?month=8-2024&collectionId=62c7b220c14f6e5949312039&crumb=BaGbBC9SWUozNDMxZWE4MzRjMTg5OTQ4ZjkyMGQ1NjUzZGJhYzNj" ==
               DromTabernaParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = DromTabernaParser.events(index_html)

      assert 30 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    setup do
      %{
        next_page_url:
          "https://www.dromtaberna.com/api/open/GetItemsByMonth?month=9-2024&collectionId=62099f5a37eb917826df65cc&crumb=BZxZJlGW0oALYzcxZDM5MjgzOGE1NmQ0ZTcyOWY3NjdhZWFmMDVi"
      }
    end

    test "returns the next page url", %{index_html: index_html, next_page_url: next_page_url} do
      assert next_page_url == DromTabernaParser.next_page_url(index_html, nil)
    end

    test "returns nil when already processed the next page", %{
      index_html: index_html,
      next_page_url: next_page_url
    } do
      assert nil == DromTabernaParser.next_page_url(index_html, next_page_url)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "66b139dee8a36e6e382dbe0c" == DromTabernaParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "66b139dee8a36e6e382dbe0c" == DromTabernaParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "2.00 - Polskatonic, 5.30 - Don Scott Trio, 8.00 - Dimitra Kahrimanidis, 11.00 to 4.00 - Sonic Sancocho" ==
               DromTabernaParser.event_title(event)
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
      assert ~D[2024-09-01] == DromTabernaParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == DromTabernaParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert nil == DromTabernaParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
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
      assert "https://www.dromtaberna.com/" == DromTabernaParser.details_url(event)
    end
  end
end
