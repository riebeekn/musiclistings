defmodule MusicListingsWeb.SitemapController do
  use MusicListingsWeb, :controller

  alias MusicListingsWeb.SEO

  def index(conn, _params) do
    venues = MusicListings.list_venues(restrict_to_pulled_venues?: false)
    events = MusicListings.list_upcoming_events()
    events_by_venue = Enum.group_by(events, & &1.venue_id)

    urls =
      [
        %{loc: SEO.canonical_url("/events"), lastmod: latest_lastmod(events)},
        %{loc: SEO.canonical_url("/venues"), lastmod: nil}
      ] ++
        Enum.map(venues, fn venue ->
          venue_events = Map.get(events_by_venue, venue.id, [])

          %{
            loc: SEO.canonical_url("/events/venue/#{venue.id}"),
            lastmod: latest_lastmod(venue_events)
          }
        end) ++
        Enum.map(events, fn event ->
          %{loc: SEO.event_url(event), lastmod: DateTime.to_iso8601(event.updated_at)}
        end)

    conn
    |> put_resp_content_type("application/xml")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, render_sitemap(urls))
  end

  defp latest_lastmod([]), do: nil

  defp latest_lastmod(events) do
    events
    |> Enum.map(& &1.updated_at)
    |> Enum.max(DateTime)
    |> DateTime.to_iso8601()
  end

  defp render_sitemap(urls) do
    entries = Enum.map_join(urls, "\n", &render_url/1)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{entries}
    </urlset>
    """
  end

  defp render_url(%{loc: loc, lastmod: nil}) do
    """
      <url>
        <loc>#{escape(loc)}</loc>
      </url>\
    """
  end

  defp render_url(%{loc: loc, lastmod: lastmod}) do
    """
      <url>
        <loc>#{escape(loc)}</loc>
        <lastmod>#{escape(lastmod)}</lastmod>
      </url>\
    """
  end

  defp escape(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  defp escape(value), do: to_string(value)
end
