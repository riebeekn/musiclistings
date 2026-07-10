defmodule MusicListingsWeb.RecentlyAddedAnalyticsTest do
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
end
