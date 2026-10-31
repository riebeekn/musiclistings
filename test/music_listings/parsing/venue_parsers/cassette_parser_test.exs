defmodule MusicListings.Parsing.VenueParsers.CassetteParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.Performers
  alias MusicListings.Parsing.Price
  alias MusicListings.Parsing.VenueParsers.CassetteParser

  setup do
    index_file_path = Path.expand("#{File.cwd!()}/test/data/cassette/index.html")

    index_html = File.read!(index_file_path)

    event =
      index_html
      |> CassetteParser.events()
      |> List.first()

    %{index_html: index_html, event: event}
  end

  # A single event card, as the listing renders it
  defp card_html(date_line, slug, ticket_link) do
    """
    <article class="event-card">
      <p class="text-small text-muted-foreground">#{date_line}</p>
      <h3><a href="/whats-on/#{slug}">Some Show</a></h3>
      #{ticket_link}
    </article>
    """
  end

  defp parse_card(date_line, slug, ticket_link \\ "") do
    [event] = date_line |> card_html(slug, ticket_link) |> CassetteParser.events()
    event
  end

  describe "source_url/0" do
    test "returns expected value" do
      assert "https://www.cassetteto.com/whats-on" == CassetteParser.source_url()
    end
  end

  describe "events/1" do
    test "returns only the live music events", %{index_html: index_html} do
      titles =
        index_html
        |> CassetteParser.events()
        |> Enum.map(&CassetteParser.event_title/1)

      assert [
               "Live at Cassette: All That and a Bag of Chips",
               "Live at Cassette: The Collective",
               "Live at Cassette: Jjared",
               "Live at Cassette: Ava Marie",
               "Davie Studios Presents: Blues NIGHT 1",
               "Davie Studios Presents: Blues NIGHT 2"
             ] == titles
    end
  end

  describe "next_page_url/2" do
    test "returns nil", %{index_html: index_html} do
      assert nil ==
               CassetteParser.next_page_url(index_html, "https://www.cassetteto.com/whats-on")
    end
  end

  describe "event_id/1" do
    test "returns the event's slug", %{event: event} do
      assert "live-at-cassette-all-that-and-a-bag-of-chips-nov-06" ==
               CassetteParser.event_id(event)
    end

    test "returns a unique id for each event", %{index_html: index_html} do
      event_ids =
        index_html
        |> CassetteParser.events()
        |> Enum.map(&CassetteParser.event_id/1)

      assert 6 == event_ids |> Enum.uniq() |> Enum.count()
    end
  end

  describe "ignored_event_id/1" do
    test "returns ignored event id", %{event: event} do
      assert "live-at-cassette-all-that-and-a-bag-of-chips-nov-06" ==
               CassetteParser.ignored_event_id(event)
    end
  end

  describe "event_title/1" do
    test "returns event title", %{event: event} do
      assert "Live at Cassette: All That and a Bag of Chips" == CassetteParser.event_title(event)
    end
  end

  describe "performers/1" do
    test "returns the event performers", %{event: event} do
      assert %Performers{
               headliner: "Live at Cassette: All That and a Bag of Chips",
               openers: []
             } == CassetteParser.performers(event)
    end
  end

  describe "event_date/1" do
    test "returns the event date", %{event: event} do
      assert ~D[2024-11-06] == CassetteParser.event_date(event)
    end

    test "prefers the listed date over the slug's" do
      event = parse_card("Sat, Nov 21 · 1pm · Live music", "some-show-nov-11")

      assert ~D[2024-11-21] == CassetteParser.event_date(event)
    end

    test "takes a recurring event's date from its slug" do
      event = parse_card("Every Saturday @ 8pm · Live music", "some-show-nov-07")

      assert ~D[2024-11-07] == CassetteParser.event_date(event)
    end
  end

  describe "additional_dates/1" do
    test "returns a list of additional dates", %{event: event} do
      assert [] == CassetteParser.additional_dates(event)
    end
  end

  describe "event_time/1" do
    test "returns the event start time", %{event: event} do
      assert ~T[21:00:00] == CassetteParser.event_time(event)
    end

    test "parses times with minutes" do
      event = parse_card("Fri, Nov 20 · 8:30pm · Live music", "some-show-nov-20")

      assert ~T[20:30:00] == CassetteParser.event_time(event)
    end

    test "returns a recurring event's start time" do
      event = parse_card("Every Saturday @ 8pm · Live music", "some-show-nov-07")

      assert ~T[20:00:00] == CassetteParser.event_time(event)
    end
  end

  describe "price/1" do
    test "returns the event price", %{event: event} do
      assert %Price{format: :unknown, hi: nil, lo: nil} == CassetteParser.price(event)
    end
  end

  describe "age_restriction/1" do
    test "returns the event age restriction", %{event: event} do
      assert :unknown == CassetteParser.age_restriction(event)
    end
  end

  describe "ticket_url/1" do
    test "returns nil when the event only offers a table booking", %{event: event} do
      assert nil == CassetteParser.ticket_url(event)
    end

    test "returns the event ticket url" do
      event =
        parse_card(
          "Fri, Nov 20 · 8pm · Live music",
          "some-show-nov-20",
          ~s(<a href="https://www.eventbrite.ca/e/some-show" target="_blank">Get tickets</a>)
        )

      assert "https://www.eventbrite.ca/e/some-show" == CassetteParser.ticket_url(event)
    end
  end

  describe "details_url/1" do
    test "returns the event details url", %{event: event} do
      assert "https://www.cassetteto.com/whats-on/live-at-cassette-all-that-and-a-bag-of-chips-nov-06" ==
               CassetteParser.details_url(event)
    end
  end
end
