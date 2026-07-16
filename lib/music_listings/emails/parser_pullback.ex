defmodule MusicListings.Emails.ParserPullback do
  @moduledoc """
  Admin email flagging venues whose parser may have silently pulled back — i.e.
  whose recent per-crawl event yield has dropped well below its own historical
  baseline. Data comes from `MusicListings.ParserHealth.pullback_report/1`.
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

  defp subject_line(%{flagged: []} = report) do
    "Parser Health — all clear (#{report.evaluated_count} venues)"
  end

  defp subject_line(%{flagged: flagged}) do
    count = length(flagged)
    "Parser Health — #{count} #{pluralize(count, "venue")} may have pulled back"
  end

  defp mjml(assigns) do
    ~H"""
    <.h1>Parser Health Check</.h1>
    <.muted>{DateHelpers.format_eastern_datetime(@report.reference)}</.muted>

    <.stat_band>
      <:stat label="Flagged" accent={if @report.flagged != [], do: "ember", else: "spotlight"}>
        {length(@report.flagged)}
      </:stat>
      <:stat label="Healthy">{@report.healthy_count}</:stat>
      <:stat label="Evaluated">{@report.evaluated_count}</:stat>
    </.stat_band>

    <%= if @report.flagged == [] do %>
      <.muted>
        All {@report.evaluated_count} active {pluralize(@report.evaluated_count, "venue")} are
        crawling within their normal range — no pullbacks detected.
      </.muted>
    <% else %>
      <.h2>Possible pullbacks</.h2>
      <.table rows={@report.flagged}>
        <:col :let={v} label="Venue">
          <%= if v.venue_website do %>
            <a href={v.venue_website} style="color:#d8ff3e;font-weight:700;text-decoration:none;">{v.venue_name}</a>
          <% else %>
            <span style="color:#ece9e0;font-weight:700;">{v.venue_name}</span>
          <% end %>
        </:col>
        <:col :let={v} label="Typical">
          <span style="color:#a8a49a;">{round_count(v.baseline_yield)}</span>
        </:col>
        <:col :let={v} label="Recent">
          <span style="color:#ff5a36;font-weight:700;">{round_count(v.recent_yield)}</span>
        </:col>
        <:col :let={v} label="Drop">
          <span style="color:#ff5a36;font-weight:700;">−{percent(v.drop_pct)}</span>
        </:col>
        <:col :let={v} label="Errors">
          <%= if v.recent_errors > 0 do %>
            <span style="color:#ff5a36;">{v.recent_errors}</span>
          <% else %>
            <span style="color:#a8a49a;">0</span>
          <% end %>
        </:col>
        <:col :let={v} label="Last crawl">
          <span style="color:#a8a49a;">{DateHelpers.format_eastern_day(v.last_crawled_at)}</span>
        </:col>
      </.table>
      <.muted>
        "Typical" is the median upcoming-event yield over the last {@report.lookback_days} days;
        "Recent" is the mean of the last {@report.recent_crawls} crawls. A venue is flagged when
        Recent falls to a fraction of Typical — worth checking the parser, especially where Errors
        is 0 (a silent break the crawl report won't catch).
      </.muted>
    <% end %>
    """
  end

  defp round_count(value), do: round(value)

  defp percent(ratio), do: "#{round(ratio * 100)}%"

  def preview do
    %{
      reference: DateTime.utc_now(),
      lookback_days: 35,
      recent_crawls: 3,
      evaluated_count: 47,
      healthy_count: 45,
      flagged: [
        %{
          venue_name: "The Phoenix Concert Theatre",
          venue_website: "https://thephoenixconcerttheatre.com",
          baseline_yield: 42,
          recent_yield: 0,
          drop_pct: 1.0,
          recent_errors: 0,
          last_crawled_at: DateTime.utc_now()
        },
        %{
          venue_name: "Horseshoe Tavern",
          venue_website: nil,
          baseline_yield: 18,
          recent_yield: 5,
          drop_pct: 0.72,
          recent_errors: 2,
          last_crawled_at: DateTime.utc_now()
        }
      ]
    }
    |> new_email()
  end

  def preview_details do
    [
      title: "Parser Pullback Check",
      description: "Weekly scan for venues whose parser yield has dropped off, via Oban cron",
      tags: [category: "Admin"]
    ]
  end
end
