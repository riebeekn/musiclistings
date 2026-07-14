defmodule MusicListings.Emails.NewThisWeekAnalytics do
  @moduledoc """
  Weekly admin email reporting engagement with the "New This Week" rail: trailing
  7-day impressions and clicks, with a prior-week comparison so we can judge
  whether the feature is gaining traction.
  """
  use MusicListings.Mailer

  alias MusicListingsUtilities.DateHelpers

  @shown "new_this_week.shown"
  @card_click "new_this_week.card_click"
  @detail_ticket_click "event.ticket_click"
  @detail_ticket_shown "event.ticket_link_shown"
  @rail_ref "new_this_week"

  # Ordered so the two internal browse surfaces sit next to each other — that
  # side-by-side is the whole point of the section. The nil bucket is mostly
  # search-engine landings, which arrive with buying intent and will always
  # convert far better than any browse surface; it's shown for context, not as
  # the rail's benchmark.
  @surfaces [
    {"new_this_week", "New This Week rail"},
    {"listing", "Events listing"},
    {"venue_page", "Venue page"},
    {nil, "Search / direct"}
  ]

  def new_email(report) do
    new()
    |> to_site_admin()
    |> from_noreply()
    |> subject(subject_line(report))
    |> body(mjml(%{report: report}))
  end

  defp subject_line(report) do
    shown = count(report.this_week, @shown)
    clicks = count(report.this_week, @card_click)

    "Rail Traction — #{shown} #{pluralize(shown, "view")}, #{clicks} #{pluralize(clicks, "click")} (last 7 days)"
  end

  defp mjml(assigns) do
    report = assigns.report

    this_conversions = Map.get(report, :this_week_conversions, %{})
    prior_conversions = Map.get(report, :prior_week_conversions, %{})
    this_ticket_shown = Map.get(report, :this_week_ticket_shown, %{})

    assigns =
      assigns
      |> Map.put(:surface_rows, surface_rows(Map.get(report, :this_week_surfaces, %{})))
      |> Map.put(:this_shown, count(report.this_week, @shown))
      |> Map.put(:this_card, count(report.this_week, @card_click))
      |> Map.put(:prior_shown, count(report.prior_week, @shown))
      |> Map.put(:prior_card, count(report.prior_week, @card_click))
      # Rail conversion funnel: card click on the rail → an event page that
      # actually showed a ticket link → ticket click (all attributed via
      # ?ref=new_this_week). Conversion is measured against the rail's
      # ticket-eligible views, not raw card clicks, so cards landing on events
      # with no ticket link (which can never convert) don't depress the rate —
      # mirroring the overall event-page CTR denominator below.
      |> Map.put(:this_rail_conv, count(this_conversions, @rail_ref))
      |> Map.put(:prior_rail_conv, count(prior_conversions, @rail_ref))
      |> Map.put(:this_rail_shown, count(this_ticket_shown, @rail_ref))
      # Overall detail-page ticket engagement (all referrers).
      |> Map.put(:this_detail_ticket, count(report.this_week, @detail_ticket_click))
      |> Map.put(:this_detail_shown, count(report.this_week, @detail_ticket_shown))

    ~H"""
    <.h1>New This Week — Rail Traction</.h1>
    <.muted>
      {DateHelpers.format_eastern_day(@report.this_week_start)} – {DateHelpers.format_eastern_date(
        @report.period_end
      )}
    </.muted>

    <.stat_band>
      <:stat label="Views" accent="spotlight">{@this_shown}</:stat>
      <:stat label="Card clicks">{@this_card}</:stat>
    </.stat_band>

    <.muted>
      Card CTR {ctr(@this_card, @this_shown)} · vs prior 7 days below
    </.muted>

    <.h2>This week vs prior week</.h2>
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
      <:col :let={row} label="Change">{change_cell(row.this, row.prior)}</:col>
    </.table>

    <.h2>Ticket CTR by surface</.h2>
    <.muted>
      Deduplicated per visitor/event/day and excluding known bots. Compare the rail
      against <strong style="color:#ece9e0;">Events listing</strong>
      — both are internal browse clicks. Search / direct is mostly search-engine
      landings, which arrive intending to buy, so it is context, not a benchmark.
    </.muted>

    <.table rows={@surface_rows}>
      <:col :let={row} label="Surface">
        <span style="color:#ece9e0;font-weight:700;">{row.label}</span>
      </:col>
      <:col :let={row} label="Ticket-eligible views">
        <span style="color:#a8a49a;">{row.shown}</span>
      </:col>
      <:col :let={row} label="Ticket clicks">
        <span style="color:#a8a49a;">{row.clicks}</span>
      </:col>
      <:col :let={row} label="Ticket CTR">
        <span style="color:#d8ff3e;font-weight:700;">{ctr(row.clicks, row.shown)}</span>
      </:col>
    </.table>

    <.h2>Rail conversions</.h2>
    <.muted>
      Full funnel: Rail card click → Event page with a ticket link → Ticket click.
      These figures are raw — not deduplicated, not bot-filtered — so they will
      read lower than the table above.
    </.muted>

    <.stat_band>
      <:stat label="Card clicks">{@this_card}</:stat>
      <:stat label="Ticket-eligible views">{@this_rail_shown}</:stat>
      <:stat label="Ticket clicks" accent="spotlight">{@this_rail_conv}</:stat>
      <:stat label="Conversion">{ctr(@this_rail_conv, @this_rail_shown)}</:stat>
    </.stat_band>

    <.muted>
      Conversion is ticket clicks ÷ ticket-eligible views (rail cards that reached
      an event with a ticket link). Rail conversions {change_cell(@this_rail_conv, @prior_rail_conv)} vs prior 7 days · Overall
      event-page ticket CTR {ctr(@this_detail_ticket, @this_detail_shown)} ({@this_detail_ticket} of {@this_detail_shown} pages where a ticket link was shown)
    </.muted>
    """
  end

  defp metric_rows(assigns) do
    [
      %{label: "Views", this: assigns.this_shown, prior: assigns.prior_shown},
      %{label: "Card clicks", this: assigns.this_card, prior: assigns.prior_card}
    ]
  end

  # Always renders every surface, including ones with no traffic — a surface
  # silently missing from the table would read as "no data collected" rather
  # than "nobody clicked", which is exactly the ambiguity this report exists to
  # remove.
  defp surface_rows(surfaces) do
    Enum.map(@surfaces, fn {ref, label} ->
      counts = Map.get(surfaces, ref, %{shown: 0, clicks: 0})

      %{label: label, shown: counts.shown, clicks: counts.clicks}
    end)
  end

  # An HEX-rendering helper that returns the styled change cell. Positive change is
  # spotlight, negative is ember, flat/undefined is dim.
  defp change_cell(current, previous) do
    assigns = %{delta: current - previous, pct: pct_change(current, previous)}

    ~H"""
    <%= cond do %>
      <% @delta > 0 -> %>
        <span style="color:#d8ff3e;font-weight:700;">▲ +{@delta} ({@pct})</span>
      <% @delta < 0 -> %>
        <span style="color:#ff5a36;font-weight:700;">▼ {@delta} ({@pct})</span>
      <% true -> %>
        <span style="color:#a8a49a;">— 0</span>
    <% end %>
    """
  end

  defp count(counts, name), do: Map.get(counts, name, 0)

  defp ctr(_numerator, 0), do: "n/a"

  defp ctr(numerator, denominator) do
    "#{Float.round(numerator / denominator * 100, 1)}%"
  end

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
      this_week: %{
        @shown => 412,
        @card_click => 63,
        @detail_ticket_click => 74,
        @detail_ticket_shown => 190
      },
      prior_week: %{
        @shown => 349,
        @card_click => 58,
        @detail_ticket_click => 61,
        @detail_ticket_shown => 170
      },
      this_week_conversions: %{@rail_ref => 18, nil => 56},
      prior_week_conversions: %{@rail_ref => 14, nil => 47},
      this_week_ticket_shown: %{@rail_ref => 47, nil => 143},
      prior_week_ticket_shown: %{@rail_ref => 39, nil => 131},
      this_week_surfaces: %{
        @rail_ref => %{shown: 47, clicks: 18},
        "listing" => %{shown: 96, clicks: 31},
        "venue_page" => %{shown: 24, clicks: 6},
        nil => %{shown: 143, clicks: 56}
      }
    }
    |> new_email()
  end

  def preview_details do
    [
      title: "New This Week Analytics",
      description: "Weekly digest of New This Week rail engagement, sent via Oban cron",
      tags: [category: "Admin"]
    ]
  end
end
