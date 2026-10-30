defmodule MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParserTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.HttpClient.Response
  alias MusicListings.Parsing.LookupFailures
  alias MusicListings.Parsing.VenueParsers.BaseParsers.MhRthTdmhParser

  # Answers every request with a 403, see MusicListings.HttpClient.Test
  @challenged_url "https://challenged.mhrth.test"
  @base_url "https://masseyhall.mhrth.com"

  setup do
    [challenged_event | _rest] =
      "test/data/massey_hall/index.html" |> File.read!() |> MhRthTdmhParser.events()

    [event] =
      "test/data/massey_hall/single_event.html" |> File.read!() |> MhRthTdmhParser.events()

    # each event is cached by its details page, so they must differ
    refute MhRthTdmhParser.details_url(challenged_event) == MhRthTdmhParser.details_url(event)

    %{challenged_event: challenged_event, event: event}
  end

  describe "dedupe_key/1" do
    test "is the event's details page", %{event: event} do
      assert "/tickets/belle-and-sebastian/" == MhRthTdmhParser.dedupe_key(event)
    end
  end

  describe "next_page_url/2" do
    test "stops at the fifth page even when the listing has more" do
      # Roy Thomson Hall's fixture is page 2 of 8
      index_html = File.read!("test/data/roy_thomson_hall/index.html")

      assert "https://roythomsonhall.mhrth.com/tickets/?page=5" ==
               MhRthTdmhParser.next_page_url(
                 index_html,
                 "https://roythomsonhall.mhrth.com/tickets/?page=4"
               )

      assert nil ==
               MhRthTdmhParser.next_page_url(
                 index_html,
                 "https://roythomsonhall.mhrth.com/tickets/?page=5"
               )
    end
  end

  # Stored under the challenged host, so any lookup the parser does make draws a
  # 403 and shows up as a lookup failure
  describe "stored lookups" do
    setup do
      %{details_url: "#{@challenged_url}/tickets/belle-and-sebastian/"}
    end

    test "an event stored with ticket links for its dates isn't looked up", %{
      event: event,
      details_url: details_url
    } do
      insert(:event,
        details_url: details_url,
        date: ~D[2026-05-25],
        time: ~T[20:00:00],
        ticket_url: "https://tickets.mhrth.com/1/"
      )

      insert(:event,
        details_url: details_url,
        date: ~D[2026-05-26],
        time: ~T[19:30:00],
        ticket_url: "https://tickets.mhrth.com/2/"
      )

      assert ~D[2026-05-25] == MhRthTdmhParser.event_date(event, @challenged_url)
      assert [~D[2026-05-26]] == MhRthTdmhParser.additional_dates(event, @challenged_url)
      assert ~T[20:00:00] == MhRthTdmhParser.event_time(event, @challenged_url)

      assert "https://tickets.mhrth.com/2/" ==
               MhRthTdmhParser.ticket_url(event, @challenged_url, ~D[2026-05-26])

      assert [] == LookupFailures.take()
    end

    test "a stored date without a ticket link is looked up", %{
      event: event,
      details_url: details_url
    } do
      insert(:event,
        details_url: details_url,
        date: ~D[2026-05-25],
        ticket_url: "https://tickets.mhrth.com/1/"
      )

      insert(:event, details_url: details_url, date: ~D[2026-05-26], ticket_url: nil)

      assert nil == MhRthTdmhParser.event_time(event, @challenged_url)
      assert [%{message: message}] = LookupFailures.take()
      assert message =~ "HTTP 403"
    end

    test "a listing date that isn't stored yet is looked up", %{
      event: event,
      details_url: details_url
    } do
      insert(:event,
        details_url: details_url,
        date: ~D[2026-05-25],
        ticket_url: "https://tickets.mhrth.com/1/"
      )

      assert nil == MhRthTdmhParser.event_time(event, @challenged_url)
      assert [%{message: message}] = LookupFailures.take()
      assert message =~ "HTTP 403"
    end
  end

  describe "challenge breaker" do
    test "a challenged lookup skips the lookups after it", %{
      challenged_event: challenged_event,
      event: event
    } do
      assert nil == MhRthTdmhParser.event_time(challenged_event, @challenged_url)
      assert [%{message: message}] = LookupFailures.take()
      assert message =~ "HTTP 403"

      assert nil == MhRthTdmhParser.event_time(event, @base_url)
      assert [%{fields: [:time, :ticket_url], message: message}] = LookupFailures.take()
      assert message =~ "skipped"
      assert message =~ "Cloudflare challenge"

      # the listing's own date still stands
      assert ~D[2026-05-25] == MhRthTdmhParser.event_date(event, @base_url)
    end

    test "a challenged listing page skips the lookups", %{event: event} do
      assert {:ok, %Response{status: 403}} =
               MhRthTdmhParser.retrieve_events_fun().("#{@challenged_url}/tickets/?page=1")

      assert nil == MhRthTdmhParser.event_time(event, @base_url)
      assert [%{message: message}] = LookupFailures.take()
      assert message =~ "skipped"
    end

    test "a listing page that gets through resets it", %{
      challenged_event: challenged_event,
      event: event
    } do
      assert nil == MhRthTdmhParser.event_time(challenged_event, @challenged_url)
      LookupFailures.take()

      assert {:ok, %Response{status: 200}} =
               MhRthTdmhParser.retrieve_events_fun().("#{@base_url}/tickets/?page=1")

      assert ~T[20:00:00] == MhRthTdmhParser.event_time(event, @base_url)
      assert [] == LookupFailures.take()
    end
  end
end
