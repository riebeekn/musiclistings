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
        <title>#{plain_text_escape(SEO.site_name())}</title>
        <link>#{escape(channel_link)}</link>
        <description><![CDATA[#{html_escape(SEO.default_description())}]]></description>
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
    title = event.title |> decode_entities() |> plain_text_escape()
    description = event |> SEO.event_meta_description() |> decode_entities() |> html_escape()
    pub_date = rfc822(event.updated_at)

    """
        <item>
          <title>#{title}</title>
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

  # RSS titles are plain text. Hex character references render correctly in
  # both XML-decoding and HTML-decoding readers, avoiding ambiguity with named
  # HTML entities.
  defp plain_text_escape(value) when is_binary(value) do
    value
    |> String.replace("&", "&#x26;")
    |> String.replace("<", "&#x3C;")
    |> String.replace(">", "&#x3E;")
  end

  # RSS descriptions are commonly parsed as HTML. Pre-escaping `&`/`<`/`>` and
  # wrapping in CDATA means the content survives both the XML and HTML decode
  # passes that feed readers perform.
  defp html_escape(value) when is_binary(value) do
    value
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp decode_entities(value) when is_binary(value) do
    value
    |> decode_numeric_entities()
    |> decode_named_entities()
  end

  defp decode_numeric_entities(value) do
    value
    |> then(&Regex.replace(~r/&#(\d+);/, &1, fn _d, num -> codepoint(String.to_integer(num)) end))
    |> then(
      &Regex.replace(~r/&#x([0-9a-fA-F]+);/, &1, fn _d, hex ->
        codepoint(String.to_integer(hex, 16))
      end)
    )
  end

  defp decode_named_entities(value) do
    value
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&apos;", "'")
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
  end

  defp codepoint(n) when n in 0..0x10FFFF, do: <<n::utf8>>
  defp codepoint(_n), do: ""
end
