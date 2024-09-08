defmodule MusicListings.Parsing.VenueParsers.PoetryJazzCafeParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.PoetryJazzCafeParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/poetry_jazz_cafe/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/poetry_jazz_cafe/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> PoetryJazzCafeParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.poetryjazzcafe.com/livemusic" == PoetryJazzCafeParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = PoetryJazzCafeParser.events(index_html)

      assert 44 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == PoetryJazzCafeParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "ben_maclean_group_2024_09_13" == PoetryJazzCafeParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "ben_maclean_group_2024_09_13" ==
               PoetryJazzCafeParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "BEN MACLEAN GROUP" == PoetryJazzCafeParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "BEN MACLEAN GROUP",
               openers: []
             } == PoetryJazzCafeParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-09-13] == PoetryJazzCafeParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == PoetryJazzCafeParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:30:00] == PoetryJazzCafeParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               PoetryJazzCafeParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == PoetryJazzCafeParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == PoetryJazzCafeParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.poetryjazzcafe.com/livemusic/2024/9/13/poetry-jazz-cafe-presents-ben-maclean-group" ==
               PoetryJazzCafeParser.details_url(event)
    end
  end
end
