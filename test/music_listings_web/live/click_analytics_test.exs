defmodule MusicListingsWeb.ClickAnalyticsTest do
  # The telemetry handler inserts from the LiveView process, which reaches the
  # test's sandboxed connection via $callers, so this can run async.  Feature
  # flags live only in the DB (no cache), so enabling one is rolled back with
  # the test's transaction - no on_exit cleanup needed (and an on_exit couldn't
  # reach the DB in async mode anyway).
  use MusicListingsWeb.ConnCase, async: true

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

  describe "non-canonical slug" do
    test "redirects to the canonical slug without carrying query params", %{
      conn: conn,
      event: event
    } do
      conn = get(conn, "/events/#{event.id}/stale-slug?ref=new_this_week")

      assert redirected_to(conn) == "/events/#{event.id}/freshly-added-show"
    end
  end

  describe "detail-page ticket link shown impression" do
    test "records an impression when the event has a ticket link",
         %{conn: conn, event: event} do
      {:ok, _view, _html} = live(conn, ~p"/events/#{event.id}/freshly-added-show")

      assert [shown] = rows("event.ticket_link_shown")
      assert shown.metadata == %{"event_id" => to_string(event.id)}
    end

    test "records no impression when the event has no ticket link", %{conn: conn} do
      event = insert(:event, ticket_url: nil, title: "No Tickets Show")

      {:ok, _view, _html} = live(conn, ~p"/events/#{event.id}/no-tickets-show")

      assert rows("event.ticket_link_shown") == []
    end
  end

  describe "detail-page ticket click" do
    test "records a click with the event id", %{conn: conn, event: event} do
      {:ok, view, _html} = live(conn, ~p"/events/#{event.id}/freshly-added-show")

      view
      |> element("a[phx-click='event_ticket_click']")
      |> render_click()

      assert [click] = rows("event.ticket_click")
      assert click.metadata == %{"event_id" => to_string(event.id)}
    end
  end
end
