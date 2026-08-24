defmodule MusicListings.Emails.WeeklyAnalytics do
  @moduledoc """
  Weekly admin email reporting site engagement: outbound ticket and TicketNetwork
  (resale) clicks, plus traction on the "New This Week" rail. Covers the trailing
  7 days with a prior-week comparison so we can judge whether things are gaining
  traction.
  """
  use MusicListings.Mailer

  alias MusicListingsUtilities.DateHelpers

  @shown "new_this_week.shown"
  @card_click "new_this_week.card_click"
  @detail_ticket_click "event.ticket_click"
  @detail_ticket_shown "event.ticket_link_shown"
  @resale_click "event.resale_click"
  @rail_ref "new_this_week"

  def new_email(report) do
    new()
    |> to_site_admin()
    |> from_noreply()
    |> subject(subject_line(report))
    |> body(mjml(%{report: report}))
  end

  defp subject_line(report) do
    ticket = count(report.this_week, @detail_ticket_click)
    resale = count(report.this_week, @resale_click)
    card = count(report.this_week, @card_click)

    "Weekly Analytics — #{ticket} ticket, #{resale} resale, #{card} rail #{pluralize(card, "click")} (last 7 days)"
  end

  defp mjml(assigns) do
    report = assigns.report

    this_conversions = Map.get(report, :this_week_conversions, %{})
    prior_conversions = Map.get(report, :prior_week_conversions, %{})
    this_ticket_shown = Map.get(report, :this_week_ticket_shown, %{})
    this_resale_surfaces = Map.get(report, :this_week_resale_surfaces, %{})

    assigns =
      assigns
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
      |> Map.put(:prior_detail_ticket, count(report.prior_week, @detail_ticket_click))
      |> Map.put(:prior_detail_shown, count(report.prior_week, @detail_ticket_shown))
      # TicketNetwork (resale) clicks, split by where they were clicked. The
      # resale chip has no impression event, so there is no CTR here — just
      # volume, which surface is driving it, and the count of events currently
      # carrying a link as a stand-in for exposure.
      |> Map.put(:this_resale, count(report.this_week, @resale_click))
      |> Map.put(:prior_resale, count(report.prior_week, @resale_click))
      |> Map.put(:this_resale_list, count(this_resale_surfaces, "list"))
      |> Map.put(:this_resale_detail, count(this_resale_surfaces, "detail"))
      |> Map.put(:resale_links_live, Map.get(report, :resale_links_live, 0))

    ~H"""
    <.h1>Weekly Analytics</.h1>
    <.muted>
      {DateHelpers.format_eastern_day(@report.this_week_start)} – {DateHelpers.format_eastern_date(
        @report.period_end
      )}
    </.muted>

    <.h2>Outbound clicks</.h2>

    <.stat_band>
      <:stat label="Ticket clicks" accent="spotlight">{@this_detail_ticket}</:stat>
      <:stat label="Resale clicks">{@this_resale}</:stat>
      <:stat label="Resale from list">{@this_resale_list}</:stat>
      <:stat label="Resale from detail">{@this_resale_detail}</:stat>
      <:stat label="Events with a resale link">{@resale_links_live}</:stat>
    </.stat_band>

    <.muted>
      Ticket clicks are the primary ticket button on the event page: CTR {ctr(
        @this_detail_ticket,
        @this_detail_shown
      )} of {@this_detail_shown} pages where a ticket link was shown, against {ctr(
        @prior_detail_ticket,
        @prior_detail_shown
      )} of {@prior_detail_shown} the prior 7 days. Compare the rates, not the click counts -
      adding ticket links to more venues raises both at once. Resale clicks are TicketNetwork
      links, counted on both the listings and the event page, across the {@resale_links_live} upcoming
      events currently carrying one. Resale {change_cell(@this_resale, @prior_resale)} vs prior 7 days
    </.muted>

    <.h2>New This Week rail</.h2>

    <.stat_band>
      <:stat label="Views" accent="spotlight">{@this_shown}</:stat>
      <:stat label="Card clicks">{@this_card}</:stat>
    </.stat_band>

    <.muted>
      Views count once per browsing session the rail rendered in; card clicks count each
      arrival on an event page via a rail link. Different denominators, so the ratio is not a
      CTR - compare each against the prior 7 days below.
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

    <.h2>Rail conversions</.h2>
    <.muted>
      Full funnel: Rail card click → Event page with a ticket link → Ticket click
    </.muted>

    <.stat_band>
      <:stat label="Card clicks">{@this_card}</:stat>
      <:stat label="Ticket-eligible views">{@this_rail_shown}</:stat>
      <:stat label="Ticket clicks" accent="spotlight">{@this_rail_conv}</:stat>
      <:stat label="Conversion">{ctr(@this_rail_conv, @this_rail_shown)}</:stat>
    </.stat_band>

    <.muted>
      Conversion is ticket clicks ÷ ticket-eligible views (rail cards that reached
      an event with a ticket link). Rail conversions {change_cell(@this_rail_conv, @prior_rail_conv)} vs prior 7 days
    </.muted>
    """
  end

  defp metric_rows(assigns) do
    [
      %{
        label: "Ticket clicks",
        this: assigns.this_detail_ticket,
        prior: assigns.prior_detail_ticket
      },
      %{
        label: "Ticket link impressions",
        this: assigns.this_detail_shown,
        prior: assigns.prior_detail_shown
      },
      %{label: "Resale clicks", this: assigns.this_resale, prior: assigns.prior_resale},
      %{label: "Rail views", this: assigns.this_shown, prior: assigns.prior_shown},
      %{label: "Rail card clicks", this: assigns.this_card, prior: assigns.prior_card}
    ]
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
        @detail_ticket_shown => 190,
        @resale_click => 21
      },
      prior_week: %{
        @shown => 349,
        @card_click => 58,
        @detail_ticket_click => 61,
        @detail_ticket_shown => 170,
        @resale_click => 16
      },
      this_week_conversions: %{@rail_ref => 18, nil => 56},
      prior_week_conversions: %{@rail_ref => 14, nil => 47},
      this_week_ticket_shown: %{@rail_ref => 47, nil => 143},
      prior_week_ticket_shown: %{@rail_ref => 39, nil => 131},
      this_week_resale_surfaces: %{"list" => 15, "detail" => 6},
      prior_week_resale_surfaces: %{"list" => 11, "detail" => 5},
      resale_links_live: 38
    }
    |> new_email()
  end

  def preview_details do
    [
      title: "Weekly Analytics",
      description: "Weekly digest of site engagement — ticket, resale and rail clicks",
      tags: [category: "Admin"]
    ]
  end
end
