defmodule Mix.Tasks.MatchTicketNetwork do
  @shortdoc "Matches the TicketNetwork catalog against our events"

  @moduledoc """
  Fetches the TicketNetwork affiliate catalog and attaches its links to our
  events, writing `events.ticketnetwork_url`.

  This normally runs automatically after the nightly crawl.  Running it by hand
  is mostly useful with `--dry-run`, which reports what would change without
  writing - the way to check the venue map and similarity threshold after
  editing either.

  Requires TICKET_NETWORK_ACCOUNT_SID and TICKET_NETWORK_AUTH_TOKEN; without
  them the task reports that it was skipped and exits cleanly.

  Usage:
    mix match_ticket_network
    mix match_ticket_network --dry-run
    mix match_ticket_network --dry-run --verbose
  """
  use Mix.Task

  alias MusicListings.Affiliates.TicketNetwork

  @requirements ["app.start"]

  # Below this, a match is worth eyeballing even though it was accepted.
  @review_score 0.95

  @impl true
  def run(args) do
    {opts, _rest} =
      OptionParser.parse!(args, strict: [dry_run: :boolean, verbose: :boolean])

    dry_run? = Keyword.get(opts, :dry_run, false)

    case TicketNetwork.analyze() do
      {:ok, :skipped} ->
        Mix.shell().info("""
        Skipped - no TicketNetwork credentials configured.
        Set TICKET_NETWORK_ACCOUNT_SID and TICKET_NETWORK_AUTH_TOKEN to enable.
        """)

      {:ok, analysis} ->
        report(analysis, dry_run?, Keyword.get(opts, :verbose, false))

      {:error, reason} ->
        Mix.raise("TicketNetwork catalog fetch failed: #{inspect(reason)}")
    end
  end

  defp report(analysis, dry_run?, verbose?) do
    stats =
      if dry_run? do
        TicketNetwork.stats(analysis)
      else
        TicketNetwork.apply_analysis(analysis)
      end

    if verbose?, do: print_matches(analysis)
    print_review_band(analysis)
    print_consecutive_runs(analysis, stats)

    Mix.shell().info("""

    #{if dry_run?, do: "Dry run - nothing written.", else: "Done."}
      items matched:        #{stats.matched}
      links set:            #{stats.linked}
      links cleared:        #{stats.cleared}
      items unmatched:      #{stats.unmatched_items}
      items at untracked venues: #{stats.untracked_items}
      events on consecutive-night runs: #{run_event_count(stats)}
    """)
  end

  defp print_matches(analysis) do
    Mix.shell().info("\nMatches:")

    print_match_lines(analysis, analysis.result.matches)
  end

  # The precision-risk band.  Anything here should be a typo, an accent, or a
  # naming convention difference - anything else means the threshold is too low.
  defp print_review_band(analysis) do
    borderline = Enum.filter(analysis.result.matches, &(&1.score < @review_score))

    Mix.shell().info(
      "\nAccepted matches below #{@review_score} (#{length(borderline)}) - review these:"
    )

    print_match_lines(analysis, borderline)
  end

  defp print_match_lines(%{events: events, venue_names: venue_names}, matches) do
    events_by_id = Map.new(events, &{&1.id, &1})

    Enum.each(matches, fn match ->
      event = Map.fetch!(events_by_id, match.event_id)

      Mix.shell().info(
        "  #{format_score(match.score)} #{event.date} " <>
          "#{venue_name(venue_names, event.venue_id)} | TN: #{match.item_name} | us: #{event.title}"
      )
    end)
  end

  # Identically titled shows on consecutive nights.  They match like anything
  # else, but a night is only as right as TicketNetwork's date, so the links
  # within a run are the ones worth spot checking.
  defp print_consecutive_runs(%{result: result, events: events}, stats) do
    linked = linked_nights(result, events)

    Mix.shell().info("\nConsecutive-night runs (#{length(result.consecutive_runs)}):")

    Enum.each(result.consecutive_runs, fn run ->
      dates = Enum.map_join(run.dates, ", ", &format_night(&1, run, linked))

      Mix.shell().info(
        "  #{venue_name(stats.venue_names, run.venue_id)} | #{run.title} | #{dates}"
      )
    end)
  end

  defp format_night(date, run, linked) do
    if MapSet.member?(linked, {run.venue_id, date}) do
      "#{Date.to_iso8601(date)} (linked)"
    else
      Date.to_iso8601(date)
    end
  end

  defp linked_nights(%{matches: matches}, events) do
    events_by_id = Map.new(events, &{&1.id, &1})

    MapSet.new(matches, fn match ->
      event = Map.fetch!(events_by_id, match.event_id)

      {event.venue_id, event.date}
    end)
  end

  defp run_event_count(stats) do
    stats.consecutive_runs |> Enum.map(&length(&1.dates)) |> Enum.sum()
  end

  defp venue_name(venue_names, venue_id) do
    Map.get(venue_names, venue_id, "venue ##{venue_id}")
  end

  defp format_score(score) do
    score |> Float.round(2) |> Float.to_string() |> String.pad_leading(4)
  end
end
