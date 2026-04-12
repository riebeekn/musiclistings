defmodule MusicListingsWeb.SitemapController do
  use MusicListingsWeb, :controller

  alias MusicListingsWeb.SEO

  def index(conn, _params) do
    venues = MusicListings.list_venues(restrict_to_pulled_venues?: false)
    events = MusicListings.list_upcoming_events()
    today_iso = Date.utc_today() |> Date.to_iso8601()

    urls =
      [
        %{
          loc: SEO.canonical_url("/events"),
          changefreq: "hourly",
          priority: "1.0",
          lastmod: today_iso
        },
        %{
          loc: SEO.canonical_url("/venues"),
          changefreq: "weekly",
          priority: "0.7",
          lastmod: today_iso
        }
      ] ++
        Enum.map(venues, fn venue ->
          %{
            loc: SEO.canonical_url("/events/venue/#{venue.id}"),
            changefreq: "daily",
            priority: "0.8",
            lastmod: today_iso
          }
        end) ++
        Enum.map(events, fn event ->
          %{
            loc: SEO.event_url(event),
            changefreq: "weekly",
            priority: "0.6",
            lastmod: event_lastmod(event)
          }
        end)

    conn
    |> put_resp_content_type("application/xml")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, render_sitemap(urls))
  end

  defp event_lastmod(%{updated_at: %DateTime{} = dt}), do: DateTime.to_iso8601(dt)

  defp render_sitemap(urls) do
    entries =
      Enum.map_join(urls, "\n", fn url ->
        """
          <url>
            <loc>#{escape(url.loc)}</loc>
            <lastmod>#{escape(url.lastmod)}</lastmod>
            <changefreq>#{url.changefreq}</changefreq>
            <priority>#{url.priority}</priority>
          </url>\
        """
      end)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{entries}
    </urlset>
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
