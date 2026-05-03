defmodule MusicListingsWeb.SitemapControllerTest do
  use MusicListingsWeb.ConnCase, async: true

  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListingsSchema.Event
  alias MusicListingsUtilities.DateHelpers

  defp set_updated_at(event_id, %DateTime{} = dt) do
    Event
    |> from(where: [id: ^event_id])
    |> Repo.update_all(set: [updated_at: dt])
  end

  describe "GET /sitemap.xml" do
    test "returns an XML sitemap with events and venues", %{conn: conn} do
      today = DateHelpers.today_eastern()
      venue = insert(:venue, name: "Sitemap Venue")
      event = insert(:event, venue: venue, date: today, title: "Sitemap Event")

      conn = get(conn, ~p"/sitemap.xml")

      assert response_content_type(conn, :xml)
      body = response(conn, 200)

      assert body =~ "<?xml"
      assert body =~ "urlset"
      assert body =~ "/events</loc>"
      assert body =~ "/venues</loc>"
      assert body =~ "/events/venue/#{venue.id}</loc>"
      assert body =~ "/events/#{event.id}/sitemap-event"
    end

    test "omits changefreq and priority tags", %{conn: conn} do
      today = DateHelpers.today_eastern()
      insert(:event, date: today, title: "Some Show")

      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      refute body =~ "<changefreq>"
      refute body =~ "<priority>"
    end

    test "excludes past events", %{conn: conn} do
      today = DateHelpers.today_eastern()
      past_event = insert(:event, date: Date.add(today, -10), title: "Old Show")

      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      refute body =~ "/events/#{past_event.id}/"
    end

    test "uses event updated_at for per-event lastmod", %{conn: conn} do
      today = DateHelpers.today_eastern()
      event_updated_at = ~U[2025-06-15 09:30:00Z]

      event = insert(:event, date: today, title: "Some Show")
      set_updated_at(event.id, event_updated_at)

      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      [_full, lastmod] =
        Regex.run(
          ~r{/events/#{event.id}/[^<]*</loc>\s*<lastmod>([^<]+)</lastmod>},
          body
        )

      {:ok, lastmod_dt, _offset} = DateTime.from_iso8601(lastmod)
      assert DateTime.diff(lastmod_dt, event_updated_at, :second) == 0
    end

    test "uses max upcoming-event updated_at for /events lastmod", %{conn: conn} do
      today = DateHelpers.today_eastern()
      older = ~U[2025-01-01 00:00:00Z]
      newer = ~U[2025-06-15 09:30:00Z]

      event_a = insert(:event, date: today, title: "A")
      event_b = insert(:event, date: today, title: "B")
      set_updated_at(event_a.id, older)
      set_updated_at(event_b.id, newer)

      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      [_full, lastmod] =
        Regex.run(~r{<loc>[^<]+/events</loc>\s*<lastmod>([^<]+)</lastmod>}, body)

      {:ok, lastmod_dt, _offset} = DateTime.from_iso8601(lastmod)
      assert DateTime.diff(lastmod_dt, newer, :second) == 0
    end

    test "uses max event updated_at at venue for venue page lastmod", %{conn: conn} do
      today = DateHelpers.today_eastern()
      venue = insert(:venue, name: "Some Venue")
      newer = ~U[2025-06-15 09:30:00Z]

      event = insert(:event, venue: venue, date: today, title: "Show")
      set_updated_at(event.id, newer)

      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      [_full, lastmod] =
        Regex.run(
          ~r{<loc>[^<]+/events/venue/#{venue.id}</loc>\s*<lastmod>([^<]+)</lastmod>},
          body
        )

      {:ok, lastmod_dt, _offset} = DateTime.from_iso8601(lastmod)
      assert DateTime.diff(lastmod_dt, newer, :second) == 0
    end

    test "omits lastmod for /venues page", %{conn: conn} do
      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      assert body =~ ~r{<loc>[^<]+/venues</loc>\s*</url>}
    end

    test "omits lastmod for venue with no upcoming events", %{conn: conn} do
      venue = insert(:venue, name: "Empty Venue")

      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      assert body =~ ~r{<loc>[^<]+/events/venue/#{venue.id}</loc>\s*</url>}
    end
  end
end
