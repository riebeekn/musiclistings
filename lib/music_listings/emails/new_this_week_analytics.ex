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
  @ticket_click "new_this_week.ticket_click"

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

    assigns =
      assigns
      |> Map.put(:this_shown, count(report.this_week, @shown))
      |> Map.put(:this_card, count(report.this_week, @card_click))
      |> Map.put(:this_ticket, count(report.this_week, @ticket_click))
      |> Map.put(:prior_shown, count(report.prior_week, @shown))
      |> Map.put(:prior_card, count(report.prior_week, @card_click))
      |> Map.put(:prior_ticket, count(report.prior_week, @ticket_click))

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
      <:stat label="Ticket clicks">{@this_ticket}</:stat>
    </.stat_band>

    <.muted>
      Card CTR {ctr(@this_card, @this_shown)} · Ticket CTR {ctr(@this_ticket, @this_shown)} · vs prior 7 days below
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
    """
  end

  defp metric_rows(assigns) do
    [
      %{label: "Views", this: assigns.this_shown, prior: assigns.prior_shown},
      %{label: "Card clicks", this: assigns.this_card, prior: assigns.prior_card},
      %{label: "Ticket clicks", this: assigns.this_ticket, prior: assigns.prior_ticket}
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
        @ticket_click => 21
      },
      prior_week: %{
        @shown => 349,
        @card_click => 58,
        @ticket_click => 22
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
