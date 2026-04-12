defmodule MusicListingsWeb.FeedController do
  use MusicListingsWeb, :controller

  alias MusicListingsWeb.SEO

  def index(conn, _params) do
    events = MusicListings.list_upcoming_events()
    build_date = DateTime.utc_now() |> rfc822()

    conn
    |> put_resp_content_type("application/rss+xml")
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_resp(200, render_feed(events, build_date))
  end

  defp render_feed(events, build_date) do
    channel_link = SEO.canonical_url("/events")
    self_link = SEO.canonical_url("/feed.xml")
    items = Enum.map_join(events, "\n", &render_item/1)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
        <title>#{escape(SEO.site_name())}</title>
        <link>#{escape(channel_link)}</link>
        <description>#{escape(SEO.default_description())}</description>
        <language>en-ca</language>
        <lastBuildDate>#{build_date}</lastBuildDate>
        <atom:link rel="self" type="application/rss+xml" href="#{escape(self_link)}" />
    #{items}
      </channel>
    </rss>
    """
  end

  defp render_item(event) do
    url = SEO.event_url(event)
    description = SEO.event_meta_description(event)
    pub_date = rfc822(event.updated_at)

    """
        <item>
          <title>#{escape(event.title)}</title>
          <link>#{escape(url)}</link>
          <guid isPermaLink="true">#{escape(url)}</guid>
          <pubDate>#{pub_date}</pubDate>
          <description><![CDATA[#{description}]]></description>
        </item>\
    """
  end

  defp rfc822(%DateTime{} = dt) do
    dt
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%a, %d %b %Y %H:%M:%S +0000")
  end

  defp escape(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
