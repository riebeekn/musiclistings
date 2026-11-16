defmodule MusicListings.Emails.WeeklyAnalytics do
  @moduledoc """
  Weekly admin email reporting outbound ticket engagement: clicks on the event
  page's ticket button against how often it was shown, compared with the prior
  week and a multi-week average, the venues and events driving those clicks, and
  how many upcoming events carry a ticket link at all (and which venues are
  losing them).
  """
  use MusicListings.Mailer

  alias MusicListingsUtilities.DateHelpers

  def new_email(report) do
    new()
    |> to_site_admin()
    |> from_noreply()
    |> subject(subject_line(report))
    |> body(mjml(%{report: report}))
  end

  defp subject_line(%{this_week: %{clicks: clicks, impressions: impressions}}) do
    "Weekly Analytics — #{clicks} ticket #{pluralize(clicks, "click")}, " <>
      "#{format_rate(rate(clicks, impressions))} CTR (last 7 days)"
  end

  defp mjml(assigns) do
    report = assigns.report

    assigns =
      assigns
      |> Map.put(:this_ctr, rate(report.this_week.clicks, report.this_week.impressions))
      |> Map.put(:prior_ctr, rate(report.prior_week.clicks, report.prior_week.impressions))
      |> Map.put(:baseline_ctr, rate(report.baseline.clicks, report.baseline.impressions))
      |> Map.put(:coverage, coverage_rate(report.ticket_coverage))
      |> Map.put(:prior_coverage, coverage_rate(report.prior_ticket_coverage))
      |> Map.put(:top_event_share, top_event_share(report))

    ~H"""
    <.h1>Weekly Analytics</.h1>
    <.muted>
      {DateHelpers.format_eastern_day(@report.this_week_start)} – {DateHelpers.format_eastern_date(
        @report.period_end
      )}
    </.muted>

    <.h2>Ticket clicks</.h2>

    <.stat_band>
      <:stat label="Ticket clicks" accent="spotlight">{@report.this_week.clicks}</:stat>
      <:stat label="Ticket link impressions">{@report.this_week.impressions}</:stat>
      <:stat label="CTR">{format_rate(@this_ctr)}</:stat>
    </.stat_band>

    <.muted>
      Ticket clicks are the primary ticket button on the event page; impressions count event
      pages where a ticket link was shown. Compare the CTR, not the click counts - adding ticket
      links to more venues raises clicks and impressions together. A single week is noisy at
      these volumes, so weigh the change against the {@report.baseline_weeks}-week average too.
    </.muted>

    <.table rows={metric_rows(assigns)}>
      <:col :let={row} label="Metric">
        <span style="color:#ece9e0;font-weight:700;">{row.label}</span>
      </:col>
      <:col :let={row} label="This week">
        <span style="color:#d8ff3e;font-weight:700;">{row.this}</span>
      </:col>
      <:col :let={row} label="Prior week">
        <span style="color:#a8a49a;">{row.prior}</span>
      </:col>
      <:col :let={row} label="Change">{row.change}</:col>
      <:col :let={row} label={"#{@report.baseline_weeks}-wk avg"}>
        <span style="color:#a8a49a;">{row.baseline}</span>
      </:col>
    </.table>

    <.muted :if={@top_event_share}>
      The top event, {@top_event_share.title}, drew {@top_event_share.clicks} of the week's {@report.this_week.clicks} clicks ({format_share(
        @top_event_share.share
      )}). Without it the week had {@top_event_share.clicks_without} clicks, against {@report.prior_week.clicks} the prior week and a {@report.baseline_weeks}-week average of {round(
        @report.baseline.clicks
      )}.
    </.muted>

    <.h2>Ticket link coverage</.h2>

    <.stat_band>
      <:stat label="Upcoming events with a ticket link" accent="spotlight">
        {format_rate(@coverage)}
      </:stat>
      <:stat label="Events with a link">{@report.ticket_coverage.with_ticket_link}</:stat>
      <:stat label="Upcoming events">{@report.ticket_coverage.total}</:stat>
    </.stat_band>

    <.muted>
      <%= if @prior_coverage do %>
        {rate_change_cell(@coverage, @prior_coverage)} vs {format_rate(@prior_coverage)} at the last report.
      <% else %>
        No earlier snapshot to compare against yet.
      <% end %>
      A drop here with no matching drop in CTR points at parsers no longer picking up ticket
      links, not at visitors.
    </.muted>

    <%= cond do %>
      <% is_nil(@report.coverage_drops) -> %>
        <.muted>Per-venue coverage changes start with the next report.</.muted>
      <% @report.coverage_drops == [] -> %>
        <.muted>
          No venue's coverage fell by {format_points(@report.coverage_drop_threshold)} pts or more since the last report.
        </.muted>
      <% true -> %>
        <.muted>
          Venues whose coverage fell by {format_points(@report.coverage_drop_threshold)} pts or more since the last report - check their parsers:
        </.muted>
        <.table rows={@report.coverage_drops}>
          <:col :let={drop} label="Venue">
            <span style="color:#ece9e0;font-weight:700;">{drop.venue_name}</span>
          </:col>
          <:col :let={drop} label="Last report">
            <span style="color:#a8a49a;">{venue_coverage_cell(drop.prior)}</span>
          </:col>
          <:col :let={drop} label="Now">{venue_coverage_cell(drop.current)}</:col>
          <:col :let={drop} label="Change">
            {rate_change_cell(coverage_rate(drop.current), coverage_rate(drop.prior))}
          </:col>
        </.table>
    <% end %>

    <.h2>Top venues</.h2>
    <%= if @report.top_venues == [] do %>
      <.muted>No ticket clicks this week.</.muted>
    <% else %>
      <.table rows={@report.top_venues}>
        <:col :let={venue} label="Venue">
          <span style="color:#ece9e0;font-weight:700;">{venue.venue_name}</span>
        </:col>
        <:col :let={venue} label="Clicks">
          <span style="color:#d8ff3e;font-weight:700;">{venue.clicks}</span>
        </:col>
      </.table>
    <% end %>

    <.h2>Top events</.h2>
    <%= if @report.top_events == [] do %>
      <.muted>No ticket clicks this week.</.muted>
    <% else %>
      <.table rows={@report.top_events}>
        <:col :let={event} label="Event"><.event_link event={event} /></:col>
        <:col :let={event} label="Venue">
          <span style="color:#a8a49a;">{event.venue_name}</span>
        </:col>
        <:col :let={event} label="Date">
          <span style="white-space:nowrap;">{DateHelpers.format_date(event.date)}</span>
        </:col>
        <:col :let={event} label="Clicks">
          <span style="color:#d8ff3e;font-weight:700;">{event.clicks}</span>
        </:col>
      </.table>
    <% end %>
    """
  end

  defp metric_rows(assigns) do
    %{this_week: this_week, prior_week: prior_week, baseline: baseline} = assigns.report

    [
      %{
        label: "Ticket clicks",
        this: this_week.clicks,
        prior: prior_week.clicks,
        change: change_cell(this_week.clicks, prior_week.clicks),
        baseline: round(baseline.clicks)
      },
      %{
        label: "Ticket link impressions",
        this: this_week.impressions,
        prior: prior_week.impressions,
        change: change_cell(this_week.impressions, prior_week.impressions),
        baseline: round(baseline.impressions)
      },
      %{
        label: "CTR",
        this: format_rate(assigns.this_ctr),
        prior: format_rate(assigns.prior_ctr),
        change: rate_change_cell(assigns.this_ctr, assigns.prior_ctr),
        baseline: format_rate(assigns.baseline_ctr)
      }
    ]
  end

  # Styled change cell for a count. Positive change is spotlight, negative is
  # ember, flat is dim.
  defp change_cell(current, previous) do
    delta = current - previous
    trend_cell(delta, "#{signed(delta)} (#{pct_change(current, previous)})")
  end

  # The top event's share of the week's clicks, and the week's clicks without it.
  # One big show can draw a sixth of a week's clicks, which makes the headline
  # count read as growth when the rest of the site was flat.
  defp top_event_share(%{top_events: [top | _rest], this_week: %{clicks: clicks}})
       when clicks > 0 do
    %{
      title: top.title,
      clicks: top.clicks,
      share: top.clicks / clicks,
      clicks_without: clicks - top.clicks
    }
  end

  defp top_event_share(_report), do: nil

  defp venue_coverage_cell(coverage) do
    "#{format_rate(coverage_rate(coverage))} (#{coverage.with_ticket_link}/#{coverage.total})"
  end

  # Styled change cell for a rate, in percentage points. The change is taken
  # between the rounded rates, so it always matches the two figures shown beside
  # it (10.7% vs 10.9% reads -0.2 pts, never -0.3).
  defp rate_change_cell(current, previous) when is_nil(current) or is_nil(previous) do
    assigns = %{}

    ~H"""
    <span style="color:#a8a49a;">n/a</span>
    """
  end

  defp rate_change_cell(current, previous) do
    delta = Float.round(percent(current) - percent(previous), 1)
    trend_cell(delta, "#{signed(delta)} pts")
  end

  defp trend_cell(delta, text) do
    assigns = %{delta: delta, text: text}

    ~H"""
    <%= cond do %>
      <% @delta > 0 -> %>
        <span style="color:#d8ff3e;font-weight:700;">▲ {@text}</span>
      <% @delta < 0 -> %>
        <span style="color:#ff5a36;font-weight:700;">▼ {@text}</span>
      <% true -> %>
        <span style="color:#a8a49a;">— 0</span>
    <% end %>
    """
  end

  defp signed(number) when number > 0, do: "+#{number}"
  defp signed(number), do: "#{number}"

  defp rate(_numerator, denominator) when denominator == 0, do: nil
  defp rate(numerator, denominator), do: numerator / denominator

  defp coverage_rate(nil), do: nil
  defp coverage_rate(%{with_ticket_link: with_link, total: total}), do: rate(with_link, total)

  defp format_rate(nil), do: "n/a"
  defp format_rate(rate), do: "#{percent(rate)}%"

  defp percent(rate), do: Float.round(rate * 100, 1)

  defp format_share(share), do: "#{round(share * 100)}%"

  defp format_points(fraction), do: round(fraction * 100)

  defp pct_change(_current, 0), do: "n/a"

  defp pct_change(current, previous) do
    pct = Float.round((current - previous) / previous * 100, 0)
    sign = if pct > 0, do: "+", else: ""
    "#{sign}#{trunc(pct)}%"
  end

  def preview do
    %{
      period_end: DateTime.utc_now(),
      this_week_start: DateTime.add(DateTime.utc_now(), -7, :day),
      prior_week_start: DateTime.add(DateTime.utc_now(), -14, :day),
      this_week: %{clicks: 74, impressions: 1890},
      prior_week: %{clicks: 61, impressions: 1700},
      baseline: %{clicks: 66.5, impressions: 1745.25},
      baseline_weeks: 4,
      top_venues: [
        %{venue_name: "Massey Hall", clicks: 18},
        %{venue_name: "History", clicks: 11},
        %{venue_name: "Horseshoe Tavern", clicks: 9},
        %{venue_name: "Lee's Palace", clicks: 7},
        %{venue_name: "The Danforth Music Hall", clicks: 5}
      ],
      top_events: [
        %{
          id: 1,
          title: "Big Headliner",
          date: Date.utc_today(),
          venue_name: "Massey Hall",
          clicks: 9
        },
        %{
          id: 2,
          title: "Indie Band",
          date: Date.utc_today(),
          venue_name: "Horseshoe Tavern",
          clicks: 6
        },
        %{id: 3, title: "Touring Act", date: Date.utc_today(), venue_name: "History", clicks: 5}
      ],
      ticket_coverage: %{total: 1420, with_ticket_link: 1105},
      prior_ticket_coverage: %{total: 1398, with_ticket_link: 1102},
      ticket_coverage_by_venue: [],
      coverage_drops: [
        %{
          venue_name: "Horseshoe Tavern",
          prior: %{total: 40, with_ticket_link: 38},
          current: %{total: 44, with_ticket_link: 25}
        }
      ],
      coverage_drop_threshold: 0.10
    }
    |> new_email()
  end

  def preview_details do
    [
      title: "Weekly Analytics",
      description:
        "Weekly digest of ticket clicks, CTR, top venues/events and ticket-link coverage",
      tags: [category: "Admin"]
    ]
  end
end
