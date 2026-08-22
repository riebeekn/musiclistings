defmodule MusicListingsWeb.EventLive.ShowTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "show" do
    setup do
      venue = insert(:venue)

      event =
        insert(:event,
          venue: venue,
          title: "Dream Theater Live",
          headliner: "Dream Theater",
          openers: ["Haken"],
          date: ~D[2026-06-01],
          time: ~T[20:00:00],
          ticket_url: "https://tickets.example.com/dt"
        )

      %{event: event, venue: venue}
    end

    test "renders event details", %{conn: conn, event: event, venue: venue} do
      {:ok, _view, html} =
        live(conn, ~p"/events/#{event.id}/dream-theater-live")

      assert html =~ "Dream Theater Live"
      assert html =~ "Haken"
      _venue = venue
    end

    test "injects MusicEvent JSON-LD", %{conn: conn, event: event} do
      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/dream-theater-live")

      assert html =~ ~s(application/ld+json)
      assert html =~ ~s("@type":"MusicEvent")
      assert html =~ "Dream Theater Live"
    end

    test "redirects to canonical slug when slug is wrong", %{conn: conn, event: event} do
      assert {:error, {:live_redirect, %{to: to}}} =
               live(conn, ~p"/events/#{event.id}/wrong-slug")

      assert to =~ "/events/#{event.id}/dream-theater-live"
    end

    test "redirects to canonical slug when slug is missing", %{conn: conn, event: event} do
      assert {:error, {:live_redirect, %{to: to}}} = live(conn, ~p"/events/#{event.id}")
      assert to =~ "/events/#{event.id}/dream-theater-live"
    end

    test "returns 404 for missing event", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, ~p"/events/999999/anything")
      end
    end

    test "renders a past event with a notice", %{conn: conn, venue: venue} do
      # mock "today" in test env is 2024-08-01, so this date is in the past
      event = insert(:event, venue: venue, title: "Past Show", date: ~D[2024-07-01])

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/past-show")

      assert html =~ "Past Show"
      assert html =~ "This event has already taken place."
    end

    test "renders a soft-deleted upcoming event with a notice", %{conn: conn, event: event} do
      {:ok, _deleted} =
        MusicListingsSchema.Event
        |> MusicListings.Repo.get!(event.id)
        |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> MusicListings.Repo.update()

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/dream-theater-live")

      assert html =~ "Dream Theater Live"
      assert html =~ "This event is no longer listed"
    end
  end

  describe "duplicate info / ticket links" do
    @shared_url "https://example.com/events/shared"

    test "hides the venue page link when it matches the ticket url", %{conn: conn} do
      event =
        insert(:event,
          venue: insert(:venue),
          title: "Shared Link Show",
          date: ~D[2026-06-01],
          ticket_url: @shared_url,
          details_url: @shared_url
        )

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/shared-link-show")

      assert html =~ "Tickets"
      refute html =~ "Venue page"
    end

    test "keeps the venue page link when the urls differ", %{conn: conn} do
      event =
        insert(:event,
          venue: insert(:venue),
          title: "Distinct Link Show",
          date: ~D[2026-06-01],
          ticket_url: @shared_url,
          details_url: "https://example.com/events/details"
        )

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/distinct-link-show")

      assert html =~ "Tickets"
      assert html =~ "Venue page"
    end

    test "keeps the venue page link when the event has no ticket url", %{conn: conn} do
      event =
        insert(:event,
          venue: insert(:venue),
          title: "Ticketless Show",
          date: ~D[2026-06-01],
          ticket_url: nil,
          details_url: "https://example.com/events/details"
        )

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/ticketless-show")

      assert html =~ "Venue page"
    end
  end

  describe "resale link (feature flag)" do
    @resale_url "https://goto.ticketnetwork.com/c/3003"

    setup do
      event =
        insert(:event,
          venue: insert(:venue),
          title: "Resale Show",
          date: ~D[2026-06-01],
          ticket_url: "https://tickets.example.com/face-value",
          ticketnetwork_url: @resale_url
        )

      %{event: event}
    end

    test "is hidden by default (flag off)", %{conn: conn, event: event} do
      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/resale-show")

      assert html =~ "Tickets"
      refute html =~ @resale_url
      refute html =~ "TicketNetwork"
    end

    test "is shown when the flag is enabled", %{conn: conn, event: event} do
      FunWithFlags.enable(:show_resale_tickets)

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/resale-show")

      assert html =~ "TicketNetwork"
      assert html =~ @resale_url
    end

    test "renders the face-value link before the resale link", %{conn: conn, event: event} do
      FunWithFlags.enable(:show_resale_tickets)

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/resale-show")

      assert :binary.match(html, "https://tickets.example.com/face-value") <
               :binary.match(html, @resale_url)
    end

    test "is not rendered when the event has no ticketnetwork url", %{conn: conn} do
      FunWithFlags.enable(:show_resale_tickets)

      event =
        insert(:event,
          venue: insert(:venue),
          title: "Plain Show",
          date: ~D[2026-06-01],
          ticketnetwork_url: nil
        )

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/plain-show")

      refute html =~ "Resale tickets"
    end

    test "JSON-LD offers keep the face-value url, not the resale url", %{
      conn: conn,
      event: event
    } do
      FunWithFlags.enable(:show_resale_tickets)

      {:ok, _view, html} = live(conn, ~p"/events/#{event.id}/resale-show")

      # The resale url is present in the page body, so scope the assertion to the
      # MusicEvent JSON-LD block: offers must advertise the face-value ticket url,
      # never the marked-up resale one.
      music_event_json =
        html
        |> String.split(~s(<script type="application/ld+json">))
        |> Enum.find(&String.contains?(&1, ~s("@type":"MusicEvent")))
        |> String.split("</script>")
        |> List.first()

      assert music_event_json =~ ~s("url":"https://tickets.example.com/face-value")
      refute music_event_json =~ "goto.ticketnetwork.com"
    end

    # Bots regularly request event pages with `Accept: application/json`. We have no
    # JSON API, so 406 is the right answer — this pins that so a future `accepts`
    # change is a deliberate one. The matching Honeybadger `exclude_errors` entry in
    # config/config.exs keeps these out of the error digest.
    test "refuses a JSON-only Accept header", %{conn: conn, event: event} do
      assert_raise Phoenix.NotAcceptableError, fn ->
        conn
        |> put_req_header("accept", "application/json")
        |> get(~p"/events/#{event.id}/dream-theater-live")
      end
    end
  end
end
