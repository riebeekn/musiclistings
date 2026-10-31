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

  describe "details_url/1" do
    test "is the same path whether the listing links by path or by full URL", %{event: event} do
      [rendered_event] =
        MhRthTdmhParser.events("""
        <div class="c-card c-card--event">
          <a class="c-card__cover-link" href="https://masseyhall.mhrth.com/tickets/belle-and-sebastian/"></a>
        </div>
        """)

      assert "/tickets/belle-and-sebastian/" == MhRthTdmhParser.details_url(event)
      assert "/tickets/belle-and-sebastian/" == MhRthTdmhParser.details_url(rendered_event)
    end
  end

  describe "showings/1" do
    test "reads each showing's date, time and ticket link" do
      assert {:ok,
              [
                {~D[2026-05-25], ~T[20:00:00], "https://tickets.mhrth.com/7047/7048/"},
                {~D[2026-05-26], ~T[20:00:00], "https://tickets.mhrth.com/7047/7049/"}
              ]} ==
               "test/data/massey_hall/detail.html" |> File.read!() |> MhRthTdmhParser.showings()
    end

    test "reads every showing of a date when they're grouped, with their end times" do
      assert {:ok,
              [
                {~D[2025-09-18], ~T[19:30:00], "https://tickets.mhrth.com/100/101/"},
                {~D[2025-09-20], ~T[19:30:00],
                 "https://www.ticketmaster.ca/event/10006300ABCD1234"},
                {~D[2025-09-20], ~T[22:00:00], "https://tickets.mhrth.com/100/104/"},
                {~D[2025-09-21], ~T[15:00:00], "https://tickets.mhrth.com/100/103/"}
              ]} ==
               "test/data/roy_thomson_hall/detail.html"
               |> File.read!()
               |> MhRthTdmhParser.showings()
    end

    test "a showing that's sold out has no ticket link, nor a time without an end time" do
      html = """
      <instance-list event-id="1" class="hydrated"><ul class="c-instances">
        <li class="c-instances__group c-instances__group--single"><div class="c-instance">
          <div class="c-instance__group-date c-instance__group-date--desktop">
            <div class="c-instance__date">Friday, December 4, 2026</div>
            <div class="c-instance__info"><div class="c-instance__doors"><p>Doors</p><span>7:00 PM</span></div></div>
          </div>
          <div class="c-instance__list-info"><div class="c-instance__button c-instance__button--desktop">
            <span class="c-btn c-btn--disabled">Sold Out</span>
          </div></div>
        </div></li>
      </ul></instance-list>
      """

      assert {:ok, [{~D[2026-12-04], nil, nil}]} == MhRthTdmhParser.showings(html)
    end

    test "is an error when the widget hadn't loaded, has nothing listed, or isn't there" do
      assert {:error, "the showings hadn't loaded"} ==
               MhRthTdmhParser.showings("""
               <instance-list event-id="1"><div class="loading-container"><svg></svg></div></instance-list>
               """)

      assert {:error, "no dated showings"} ==
               MhRthTdmhParser.showings("""
               <instance-list event-id="1" class="hydrated"><div class="c-instance__empty">
                 <h2 class="c-heading">Tickets for this event are currently unavailable.</h2>
               </div></instance-list>
               """)

      assert {:error, "no showings widget on the details page"} ==
               MhRthTdmhParser.showings("<html><body><h1>Just a moment...</h1></body></html>")
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
