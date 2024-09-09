defmodule MusicListings.Parsing.VenueParsers.PrimalNoteParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.PrimalNoteParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/primal_note/index.html")

    single_event_file_path =
      Path.expand("#{File.cwd!()}/test/data/primal_note/single_event.html")

    index_html = File.read!(index_file_path)

    event =
      single_event_file_path
      |> File.read!()
      |> PrimalNoteParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://primalnote.com/events" == PrimalNoteParser.source_url()
    end
  end

  describe "events/1" do
    test "returns expected events", %{index_html: index_html} do
      events = PrimalNoteParser.events(index_html)

      assert 13 = Enum.count(events)
    end
  end

  describe "next_page_url/2" do
    test "returns the next page url", %{index_html: index_html} do
      assert nil == PrimalNoteParser.next_page_url(index_html, nil)
    end
  end

  describe "event_id/1" do
    test "returns event id", %{event: event} do
      assert "autumnal_assault_beast_of_the_north_productions_feat_vesication_apegod_deity_and_abysmal_whore_2024_10_11" ==
               PrimalNoteParser.event_id(event)
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "autumnal_assault_beast_of_the_north_productions_feat_vesication_apegod_deity_and_abysmal_whore_2024_10_11" ==
               PrimalNoteParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Autumnal Assault (Beast of the North Productions) feat. Vesication, Apegod, Deity, and Abysmal Whore" ==
               PrimalNoteParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner:
                 "Autumnal Assault (Beast of the North Productions) feat. Vesication, Apegod, Deity, and Abysmal Whore",
               openers: []
             } == PrimalNoteParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-10-11] == PrimalNoteParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == PrimalNoteParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[20:00:00] == PrimalNoteParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} ==
               PrimalNoteParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == PrimalNoteParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns the event ticket url", %{event: event} do
      assert nil == PrimalNoteParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://primalnote.com/events/autumnal-assault-beast-of-the-north-productions-feat-vesication-apegod-deity-and-abysmal-whore" ==
               PrimalNoteParser.details_url(event)
    end
  end
end
