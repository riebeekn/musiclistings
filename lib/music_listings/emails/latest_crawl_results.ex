defmodule MusicListings.Emails.LatestCrawlResults do
  @moduledoc """
  Email that sends latest crawl result summary
  """
  use MusicListings.Mailer

  alias MusicListings.Events
  alias MusicListings.Repo
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias MusicListingsSchema.VenueCrawlSummary
  alias MusicListingsUtilities.DateHelpers

  @doc """
  Builds the crawl summary email.

  The events the crawl added are looked up from its time window unless passed in -
  `preview/0` supplies its own so it can render without touching the database.
  """
  def new_email(crawl_summary, added_events \\ nil) do
    crawl_summary =
      Repo.preload(crawl_summary, crawl_errors: [:venue], venue_crawl_summaries: [:venue])

    added_events = added_events || Events.list_events_added_during_crawl(crawl_summary)

    new()
    |> to_site_admin()
    |> from_noreply()
    |> subject(subject_line(crawl_summary))
    |> body(mjml(%{crawl_summary: crawl_summary, added_events: added_events}))
  end

  defp subject_line(%{new: new, errors: errors}) when errors > 0 do
    "Crawl Report — #{new} new, #{errors} #{pluralize(errors, "error")}"
  end

  defp subject_line(%{new: new}) do
    "Crawl Report — #{new} new #{pluralize(new, "event")}"
  end

  defp mjml(assigns) do
    assigns =
      assigns
      |> Map.put(:venue_rows, sort_venues(assigns.crawl_summary.venue_crawl_summaries))
      |> Map.put(:error_count, Enum.count(assigns.crawl_summary.crawl_errors))
      |> Map.put(:added_event_count, Enum.count(assigns.added_events))
      |> Map.put(:no_events_venues, no_events_venues(assigns.crawl_summary.crawl_errors))

    ~H"""
    <.h1>Nightly Crawl Report</.h1>
    <.muted>{DateHelpers.format_eastern_datetime(@crawl_summary.inserted_at)}</.muted>

    <.stat_band>
      <:stat label="New" accent="spotlight">{@crawl_summary.new}</:stat>
      <:stat label="Updated">{@crawl_summary.updated}</:stat>
      <:stat label="Errors" accent={if @crawl_summary.errors > 0, do: "ember"}>
        {@crawl_summary.errors}
      </:stat>
    </.stat_band>

    <%= if @crawl_summary.new > 0 do %>
      <.muted>
        {@crawl_summary.new} new {pluralize(@crawl_summary.new, "event")} across {venues_with_new(
          @venue_rows
        )} {pluralize(venues_with_new(@venue_rows), "venue")} · {@crawl_summary.duplicate} unchanged · {@crawl_summary.ignored} ignored
      </.muted>
    <% else %>
      <.muted>
        No new events were found tonight · {@crawl_summary.updated} updated · {@crawl_summary.duplicate} unchanged
      </.muted>
    <% end %>

    <.h2>By venue</.h2>
    <.table rows={@venue_rows} include_footer?={true}>
      <:col :let={vcs} label="Venue">
        <%= if vcs.new > 0 do %>
          <span style="color:#d8ff3e;">●</span>
          <span style="color:#ece9e0;font-weight:700;">{vcs.venue.name}</span>
        <% else %>
          <span style="color:#a8a49a;">{vcs.venue.name}</span>
        <% end %>
      </:col>
      <:col :let={vcs} label="New">
        <%= if vcs.new > 0 do %>
          <span style="color:#d8ff3e;font-weight:700;">{vcs.new}</span>
        <% else %>
          <span style="color:#a8a49a;">—</span>
        <% end %>
      </:col>
      <:col :let={vcs} label="Updated">{vcs.updated}</:col>
      <:col :let={vcs} label="Dupes">
        <span style="color:#a8a49a;">{vcs.duplicate}</span>
      </:col>
      <:col :let={vcs} label="Ignored">
        <span style="color:#a8a49a;">{vcs.ignored}</span>
      </:col>
      <:col :let={vcs} label="Errors">
        <%= if vcs.errors > 0 do %>
          <span style="color:#ff5a36;font-weight:700;">{vcs.errors}</span>
        <% else %>
          <span style="color:#a8a49a;">0</span>
        <% end %>
      </:col>
      <:footer_col>Total</:footer_col>
      <:footer_col><span style="color:#d8ff3e;">{@crawl_summary.new}</span></:footer_col>
      <:footer_col>{@crawl_summary.updated}</:footer_col>
      <:footer_col>{@crawl_summary.duplicate}</:footer_col>
      <:footer_col>{@crawl_summary.ignored}</:footer_col>
      <:footer_col>
        <span style={if @crawl_summary.errors > 0, do: "color:#ff5a36;"}>{@crawl_summary.errors}</span>
      </:footer_col>
    </.table>

    <%= if @error_count > 0 do %>
      <.h2>Errors ({@error_count})</.h2>
      <%= for crawl_error <- Enum.sort_by(@crawl_summary.crawl_errors, & &1.venue.name) do %>
        <mj-text padding="6px 0">
          <div style="border-left:3px solid #ff5a36;background-color:#1c1c1d;border-radius:6px;padding:12px 14px;">
            <div style="font-family:'Big Shoulders Display','Hanken Grotesk',Helvetica,Arial,sans-serif;font-size:15px;font-weight:700;color:#ff5a36;">
              {crawl_error.venue.name}
              <span style="color:#a8a49a;font-weight:400;font-size:12px;">· error #{crawl_error.id}</span>
            </div>
            <div style="color:#ece9e0;font-size:12px;line-height:1.5;padding-top:8px;white-space:pre-wrap;font-family:'Space Mono','SFMono-Regular',monospace;">
              {crawl_error.error}
            </div>
            <%= if crawl_error.type != :no_events_error do %>
              <div style="color:#a8a49a;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;padding-top:10px;">
                Raw event
              </div>
              <div style="color:#a8a49a;font-size:11px;line-height:1.45;padding-top:4px;word-break:break-word;font-family:'Space Mono','SFMono-Regular',monospace;">
                {crawl_error.raw_event}
              </div>
            <% end %>
          </div>
        </mj-text>
      <% end %>
    <% end %>

    <%= if @no_events_venues != [] do %>
      <.h2>Crawl locally</.h2>
      <.muted>
        Run this from the project root to re-crawl every venue that found no events:
      </.muted>
      <mj-text padding="6px 0">
        <div style="border-left:3px solid #d8ff3e;background-color:#1c1c1d;border-radius:6px;padding:12px 14px;">
          <div style="color:#d8ff3e;font-size:12px;line-height:1.45;word-break:break-word;font-family:'Space Mono','SFMono-Regular',monospace;">
            {local_crawl_command(@no_events_venues)}
          </div>
          <div style="color:#a8a49a;font-size:11px;line-height:1.45;padding-top:8px;">
            {@no_events_venues |> Enum.map_join(" · ", & &1.name)}
          </div>
        </div>
      </mj-text>
    <% end %>

    <%= if @added_event_count > 0 do %>
      <.h2>New events ({@added_event_count})</.h2>
      <.table rows={@added_events}>
        <:col :let={event} label="Venue">
          <span style="color:#a8a49a;">{event.venue.name}</span>
        </:col>
        <:col :let={event} label="Date">
          <span style="white-space:nowrap;">{DateHelpers.format_date(event.date)}</span>
        </:col>
        <:col :let={event} label="Event">
          <span style="color:#ece9e0;font-weight:700;">{event.title}</span>
        </:col>
      </.table>
    <% end %>
    """
  end

  defp no_events_venues(crawl_errors) do
    crawl_errors
    |> Enum.filter(&(&1.type == :no_events_error))
    |> Enum.map(& &1.venue)
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(& &1.name)
  end

  # A venue reports no events either because its parser has silently broken, or
  # because its origin blocks Render's egress IP and the crawl never reaches it.
  # Either way the fix starts by crawling it from a machine that can reach it, so
  # hand over a single command covering every venue that came up empty.
  #
  # Identify venues by parser_module_name, not id: this command is written by
  # prod but pasted into a local shell, and venue ids differ between the two.
  defp local_crawl_command(venues) do
    "bin/crawl-venue.sh #{Enum.map_join(venues, " ", & &1.parser_module_name)}"
  end

  defp sort_venues(venue_crawl_summaries) do
    Enum.sort_by(venue_crawl_summaries, fn vcs ->
      {if(vcs.new > 0, do: 0, else: 1), vcs.venue.name}
    end)
  end

  defp venues_with_new(venue_rows) do
    Enum.count(venue_rows, &(&1.new > 0))
  end

  def preview do
    # venues
    v1 = build_venue(1, "First Venue", "FirstVenueParser")
    v2 = build_venue(2, "Second Venue", "SecondVenueParser")
    v3 = build_venue(3, "Quiet Venue", "QuietVenueParser")
    v4 = build_venue(4, "Blocked Venue", "BlockedVenueParser")

    # venue summaries
    vcs1 =
      build_venue_crawl_summary(v1, %{
        duplicate: 2,
        ignored: 4,
        new: 2,
        updated: 16,
        errors: 1
      })

    vcs2 =
      build_venue_crawl_summary(v2, %{
        duplicate: 6,
        ignored: 2,
        new: 10,
        updated: 8,
        errors: 2
      })

    vcs3 =
      build_venue_crawl_summary(v3, %{
        duplicate: 5,
        ignored: 0,
        new: 0,
        updated: 0,
        errors: 0
      })

    vcs4 =
      build_venue_crawl_summary(v4, %{
        duplicate: 0,
        ignored: 0,
        new: 0,
        updated: 0,
        errors: 1
      })

    # errors
    ce1 = build_crawl_error(1, v1)
    ce2 = build_crawl_error(2, v2)
    ce3 = build_crawl_error(3, v2)
    ce4 = build_no_events_error(4, v3)
    ce5 = build_no_events_error(5, v4)

    # events added by this crawl
    added_events = [
      build_event(v1, "Sunset Rubdown", ~D[2026-08-14]),
      build_event(v1, "The Weather Station", ~D[2026-09-02]),
      build_event(v2, "Badge Époque Ensemble", ~D[2026-08-21])
    ]

    build_crawl_summary()
    |> Map.put(:crawl_errors, [ce1, ce2, ce3, ce4, ce5])
    |> Map.put(:venue_crawl_summaries, [vcs1, vcs2, vcs3, vcs4])
    |> new_email(added_events)
  end

  def preview_details do
    [
      title: "Latest Crawl Results",
      description: "Sent daily via the Oban Job that executes the crawler",
      tags: [category: "Admin"]
    ]
  end

  defp build_venue(id, name, parser_module_name) do
    %Venue{
      id: id,
      name: name,
      parser_module_name: parser_module_name
    }
  end

  defp build_crawl_summary do
    %CrawlSummary{
      duplicate: 13,
      ignored: 6,
      new: 12,
      updated: 24,
      errors: 3,
      inserted_at: DateTime.utc_now()
    }
  end

  defp build_venue_crawl_summary(venue, %{
         duplicate: duplicate,
         ignored: ignored,
         new: new,
         updated: updated,
         errors: errors
       }) do
    %VenueCrawlSummary{
      venue: venue,
      venue_id: venue.id,
      duplicate: duplicate,
      ignored: ignored,
      new: new,
      updated: updated,
      errors: errors
    }
  end

  defp build_crawl_error(id, venue) do
    %CrawlError{
      id: id,
      venue: venue,
      venue_id: venue.id,
      type: :parse_error,
      error: example_error(),
      raw_event: example_raw_event()
    }
  end

  defp build_event(venue, title, date) do
    %Event{
      venue: venue,
      venue_id: venue.id,
      title: title,
      date: date
    }
  end

  defp build_no_events_error(id, venue) do
    %CrawlError{
      id: id,
      venue: venue,
      venue_id: venue.id,
      type: :no_events_error,
      error: "No events found for #{venue.name}"
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
