defmodule MusicListingsWeb.ClickAnalyticsTest do
  # async: false so the SQL sandbox runs in shared mode — the telemetry handler
  # inserts from the LiveView process, which needs the test's connection.
  use MusicListingsWeb.ConnCase, async: false

  import Ecto.Query
  import Phoenix.LiveViewTest

  alias MusicListings.Repo
  alias MusicListingsSchema.AnalyticsEvent
  alias MusicListingsUtilities.DateHelpers

  setup do
    venue = insert(:venue)

    event =
      insert(:event,
        venue: venue,
        title: "Freshly Added Show",
        date: DateHelpers.today_eastern(),
        ticket_url: "https://tickets.example.com/fresh"
      )

    %{event: event}
  end

  defp rows(name) do
    AnalyticsEvent
    |> where([analytics_event], analytics_event.name == ^name)
    |> Repo.all()
  end

  describe "shown impression" do
    test "is recorded once when the rail renders with the flag on", %{conn: conn} do
      FunWithFlags.enable(:show_recently_added)

      {:ok, view, html} = live(conn, ~p"/events")
      assert html =~ "New This Week"

      assert [shown] = rows("new_this_week.shown")
      assert shown.metadata == %{}

      # Re-running handle_params (e.g. a filter/pagination patch) must not re-count.
      render_patch(view, ~p"/events")
      assert length(rows("new_this_week.shown")) == 1
    end

    test "is not recorded when the flag is off", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/events")

      refute html =~ "New This Week"
      assert rows("new_this_week.shown") == []
    end
  end

  describe "card click" do
    setup do
      FunWithFlags.enable(:show_recently_added)
      on_exit(fn -> FunWithFlags.disable(:show_recently_added) end)
      :ok
    end

    test "is recorded when arriving via ?ref=new_this_week", %{conn: conn, event: event} do
      {:ok, _view, _html} =
        live(conn, "/events/#{event.id}/freshly-added-show?ref=new_this_week")

      assert [click] = rows("new_this_week.card_click")
      assert click.metadata["event_id"] == to_string(event.id)
    end

    test "is not recorded without the ref param", %{conn: conn, event: event} do
      {:ok, _view, _html} = live(conn, ~p"/events/#{event.id}/freshly-added-show")

      assert rows("new_this_week.card_click") == []
    end

    test "is not recorded when the rail flag is off", %{conn: conn, event: event} do
      # ?ref=new_this_week URLs stay in circulation long after the rail stops
      # rendering - bookmarked, shared, indexed - and counting those arrivals as
      # rail clicks is what made the metric read a 94% card CTR with no rail.
      FunWithFlags.disable(:show_recently_added)

      {:ok, _view, _html} =
        live(conn, "/events/#{event.id}/freshly-added-show?ref=new_this_week")

      assert rows("new_this_week.card_click") == []
    end

    test "survives a non-canonical slug redirect (?ref is preserved)", %{conn: conn, event: event} do
      # A rail link whose slug isn't canonical must redirect to the canonical
      # slug *keeping* ?ref, otherwise the referrer is lost before any ticket
      # click and the conversion can never be attributed to the rail.
      conn = get(conn, "/events/#{event.id}/stale-slug?ref=new_this_week")

      assert redirected_to(conn) ==
               "/events/#{event.id}/freshly-added-show?ref=new_this_week"
    end
  end

  describe "detail-page ticket link shown impression" do
    test "records an impression carrying the ref when the event has a ticket link",
         %{conn: conn, event: event} do
      {:ok, _view, _html} =
        live(conn, "/events/#{event.id}/freshly-added-show?ref=new_this_week")

      assert [shown] = rows("event.ticket_link_shown")
      assert shown.metadata["event_id"] == to_string(event.id)
      assert shown.metadata["ref"] == "new_this_week"
    end

    test "records no impression when the event has no ticket link", %{conn: conn} do
      event = insert(:event, ticket_url: nil, title: "No Tickets Show")

      {:ok, _view, _html} = live(conn, ~p"/events/#{event.id}/no-tickets-show")

      assert rows("event.ticket_link_shown") == []
    end
  end

  describe "detail-page ticket click" do
    test "records a click attributed to the rail referrer", %{conn: conn, event: event} do
      {:ok, view, _html} =
        live(conn, "/events/#{event.id}/freshly-added-show?ref=new_this_week")

      view
      |> element("a[phx-click='event_ticket_click']")
      |> render_click()

      assert [click] = rows("event.ticket_click")
      assert click.metadata["event_id"] == to_string(event.id)
      assert click.metadata["ref"] == "new_this_week"
    end

    test "records a nil ref for a direct (non-rail) visit", %{conn: conn, event: event} do
      {:ok, view, _html} = live(conn, ~p"/events/#{event.id}/freshly-added-show")

      view
      |> element("a[phx-click='event_ticket_click']")
      |> render_click()

      assert [click] = rows("event.ticket_click")
      assert click.metadata["ref"] == nil
    end
  end

  describe "resale (TicketNetwork) click" do
    setup do
      FunWithFlags.enable(:show_resale_tickets)

      on_exit(fn -> FunWithFlags.disable(:show_resale_tickets) end)

      resale_event =
        insert(:event,
          title: "Resale Show",
          date: DateHelpers.today_eastern(),
          ticket_url: "https://tickets.example.com/resale",
          ticketnetwork_url: "https://gotickets.example.com/resale"
        )

      %{resale_event: resale_event}
    end

    test "is recorded from the event detail page with the rail referrer",
         %{conn: conn, resale_event: resale_event} do
      {:ok, view, _html} =
        live(conn, "/events/#{resale_event.id}/resale-show?ref=new_this_week")

      view
      |> element("a[phx-click='event_resale_click']")
      |> render_click()

      assert [click] = rows("event.resale_click")
      assert click.metadata["event_id"] == to_string(resale_event.id)
      assert click.metadata["surface"] == "detail"
      assert click.metadata["ref"] == "new_this_week"
    end

    test "is recorded from a listings row with a nil ref",
         %{conn: conn, resale_event: resale_event} do
      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#event-#{resale_event.id} a[phx-click='event_resale_click']")
      |> render_click()

      assert [click] = rows("event.resale_click")
      assert click.metadata["event_id"] == to_string(resale_event.id)
      assert click.metadata["surface"] == "list"
      assert click.metadata["ref"] == nil
    end

    test "is recorded from a venue page listings row",
         %{conn: conn, resale_event: resale_event} do
      {:ok, view, _html} = live(conn, ~p"/events/venue/#{resale_event.venue_id}")

      view
      |> element("#event-#{resale_event.id} a[phx-click='event_resale_click']")
      |> render_click()

      assert [click] = rows("event.resale_click")
      assert click.metadata["surface"] == "list"
    end
  end
end
