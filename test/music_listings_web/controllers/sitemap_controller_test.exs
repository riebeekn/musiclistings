defmodule MusicListingsWeb.SitemapControllerTest do
  use MusicListingsWeb.ConnCase, async: true

  alias MusicListingsUtilities.DateHelpers

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

    test "excludes past events", %{conn: conn} do
      today = DateHelpers.today_eastern()
      past_event = insert(:event, date: Date.add(today, -10), title: "Old Show")

      conn = get(conn, ~p"/sitemap.xml")
      body = response(conn, 200)

      refute body =~ "/events/#{past_event.id}/"
    end
  end
end
