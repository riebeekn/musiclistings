defmodule MusicListings.Emails.LatestCrawlResults do
  @moduledoc """
  Email that sends latest crawl result summary
  """
  use MusicListings.Mailer

  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Venue
  alias MusicListingsSchema.VenueCrawlSummary

  def new_email(crawl_summary) do
    crawl_summary =
      Repo.preload(crawl_summary, crawl_errors: [:venue], venue_crawl_summaries: [:venue])

    new()
    |> to(Application.get_env(:music_listings, :admin_email))
    |> from({"Toronto Music Listings", "no-reply@example.com"})
    |> subject("Latest Crawl Results")
    |> body(mjml(%{crawl_summary: crawl_summary}))
  end

  defp mjml(assigns) do
    ~H"""
    <.h1>
      Latest Crawl Results - <%= DateTime.to_string(@crawl_summary.inserted_at) %>
    </.h1>
    <.h2>Summary</.h2>
    <.table
      rows={@crawl_summary.venue_crawl_summaries |> Enum.sort_by(& &1.venue.name)}
      include_footer?={true}
    >
      <:col :let={venue_crawl_summary} label="Venue">
        <%= venue_crawl_summary.venue.name %>
      </:col>
      <:col :let={venue_crawl_summary} label="New">
        <%= venue_crawl_summary.new %>
      </:col>
      <:col :let={venue_crawl_summary} label="Updated">
        <%= venue_crawl_summary.updated %>
      </:col>
      <:col :let={venue_crawl_summary} label="Duplicates">
        <%= venue_crawl_summary.duplicate %>
      </:col>
      <:col :let={venue_crawl_summary} label="Parse Errors">
        <%= venue_crawl_summary.parse_errors %>
      </:col>
      <:footer_col>
        Total
      </:footer_col>
      <:footer_col>
        <%= @crawl_summary.new %>
      </:footer_col>
      <:footer_col>
        <%= @crawl_summary.updated %>
      </:footer_col>
      <:footer_col>
        <%= @crawl_summary.duplicate %>
      </:footer_col>
      <:footer_col>
        <%= @crawl_summary.parse_errors %>
      </:footer_col>
    </.table>
    <%= if Enum.count(@crawl_summary.crawl_errors) > 0 do %>
      <.h2>Errors</.h2>
      <%= for crawl_error <- @crawl_summary.crawl_errors |> Enum.sort_by(& &1.venue.name) do %>
        <.text><b>Venue: </b><%= crawl_error.venue.name %></.text>
        <.text><b>Error: </b><%= crawl_error.error %></.text>
        <.text><b>Raw Event: </b><%= crawl_error.raw_event %></.text>
        <mj-divider border-width="1px" border-style="dashed" border-color="lightgrey" />
      <% end %>
    <% end %>
    """
  end

  def preview do
    # venues
    v1 = build_venue("First Venue")
    v2 = build_venue("Second Venue")

    # venue summaries
    vcs1 =
      build_venue_crawl_summary(v1, %{
        duplicate: 2,
        new: 2,
        updated: 16,
        parse_errors: 1
      })

    vcs2 =
      build_venue_crawl_summary(v2, %{
        duplicate: 6,
        new: 10,
        updated: 8,
        parse_errors: 2
      })

    # errors
    ce1 = build_crawl_error(v1)
    ce2 = build_crawl_error(v2)
    ce3 = build_crawl_error(v2)

    build_crawl_summary()
    |> Map.put(:crawl_errors, [ce1, ce2, ce3])
    |> Map.put(:venue_crawl_summaries, [vcs1, vcs2])
    |> new_email()
  end

  def preview_details do
    [
      title: "Latest Crawl Results",
      description: "Sent daily via the Oban Job that executes the crawler",
      tags: [category: "Admin"]
    ]
  end

  defp build_venue(name) do
    %Venue{
      name: name,
      parser_module_name: "#{name}parser"
    }
  end

  defp build_crawl_summary do
    %CrawlSummary{
      duplicate: 8,
      new: 12,
      updated: 24,
      parse_errors: 3,
      inserted_at: DateTime.utc_now()
    }
  end

  defp build_venue_crawl_summary(venue, %{
         duplicate: duplicate,
         new: new,
         updated: updated,
         parse_errors: parse_errors
       }) do
    %VenueCrawlSummary{
      venue: venue,
      duplicate: duplicate,
      new: new,
      updated: updated,
      parse_errors: parse_errors
    }
  end

  defp build_crawl_error(venue) do
    %CrawlError{
      venue: venue,
      type: :parse_error,
      error: example_error(),
      raw_event: example_raw_event()
    }
  end

  defp example_error do
    """
    ** (FunctionClauseError) no function clause matching in MusicListings.Parsing.Parser.month_string_to_number/1
    (music_listings 0.1.0) lib/music_listings/parsing/parser.ex:138: MusicListings.Parsing.Parser.month_string_to_number("thursday")
    (music_listings 0.1.0) lib/music_listings/parsing/el_mocambo_parser.ex:61: MusicListings.Parsing.ElMocamboParser.event_date/1
    (music_listings 0.1.0) lib/music_listings/parsing/el_mocambo_parser.ex:38: MusicListings.Parsing.ElMocamboParser.event_id/1
    (music_listings 0.1.0) lib/music_listings/crawler/event_parser.ex:51: MusicListings.Crawler.EventParser.parse_event/3
    (music_listings 0.1.0) lib/music_listings/crawler/event_parser.ex:26: anonymous fn/4 in MusicListings.Crawler.EventParser.parse_events/4
    (elixir 1.17.1) lib/task/supervised.ex:101: Task.Supervised.invoke_mfa/2
    (elixir 1.17.1) lib/task/supervised.ex:36: Task.Supervised.reply/4
    """
  end

  defp example_raw_event do
    """
    #Meeseeks.Result<{ <article id="post-8043" class="stratum-advanced-posts__post"> <div class="stratum-advanced-posts__post-wrapper"> <div class="stratum-advanced-posts__post-thumbnail"> <a href="https://elmocambo.com/event/the-lemon-pistols-casa-limone-release-party/" class="stratum-advanced-posts__post-link"> <img loading="lazy" decoding="async" width="1259" height="1260" src="https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74.jpg" class="stratum-advanced-posts__post-thumbnail-image wp-post-image" alt="The Lemon Pistols: Casa Limone Release Party" srcset="https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74.jpg 1259w, https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74-300x300.jpg?crop=1 300w, https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74-1024x1024.jpg 1024w, https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74-150x150.jpg?crop=1 150w, https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74-768x769.jpg 768w, https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74-600x600.jpg 600w, https://elmocambo.com/wp-content/uploads/2023/02/de3c5d1b-79e1-4fc5-b01f-1857fa9dcb74-100x100.jpg?crop=1 100w" sizes="(max-width: 1259px) 100vw, 1259px" /> <div class="stratum-advanced-posts__post-thumbnail-overlay"></div> </a> </div> <div class="stratum-advanced-posts__content-wrapper"> <div class="stratum-advanced-posts__entry-header"> <h3 class="stratum-advanced-posts__post-title"><a href="https://elmocambo.com/event/the-lemon-pistols-casa-limone-release-party/">The Lemon Pistols: Casa Limone Release Party</a></h3> <div class="stratum-advanced-posts__entry-meta"><span class="stratum-advanced-posts__post-date"><time datetime="2023-02-02T02:04:51-05:00"><a href="https://elmocambo.com/2023/02/02/">Thursday 02, Feb</a></time></span></div> </div> <div class="stratum-advanced-posts__post-content"></div> <div class="stratum-advanced-posts__entry-footer"> <div class="stratum-advanced-posts__read-more"><a href="https://elmocambo.com/event/the-lemon-pistols-casa-limone-release-party/">BUY TICKETS</a></div> </div> </div> </div> </article> }>
    """
  end
end
