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
      assert shown.metadata["count"] == 1

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
  end

  describe "ticket click" do
    test "is recorded when the rail Tickets link is clicked", %{conn: conn, event: event} do
      FunWithFlags.enable(:show_recently_added)

      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("a[phx-click='recently_added_ticket_click']")
      |> render_click()

      assert [click] = rows("new_this_week.ticket_click")
      assert click.metadata["event_id"] == to_string(event.id)
    end
  end
end
