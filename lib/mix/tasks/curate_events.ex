defmodule Mix.Tasks.CurateEvents do
  @shortdoc "Flags upcoming listings that look wrong, for review"

  @moduledoc """
  Runs the curation rules over every upcoming event and prints the review queue.

  This normally runs automatically after the nightly crawl, which reports the
  queue in the crawl summary email.  Running it by hand is mostly useful with
  `--dry-run`, which prints what the rules currently match without writing any
  flags - the way to check a rule after editing one.

  Combine with `USE_PROD_DB=true` to tune the rules against real data.

  Usage:
    mix curate_events
    mix curate_events --dry-run
  """
  use Mix.Task

  alias MusicListings.Curation
  alias MusicListingsUtilities.DateHelpers

  @requirements ["app.start"]

  @impl true
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [dry_run: :boolean])

    if Keyword.get(opts, :dry_run, false) do
      Mix.shell().info("Dry run - no flags written.\n")
    else
      Curation.run()
    end

    Curation.list_open_flags()
    |> print_queue()
  end

  defp print_queue([]) do
    Mix.shell().info("Nothing to review.")
  end

  defp print_queue(flags) do
    {duplicates, titles} = Enum.split_with(flags, &(&1.type == :duplicate_event))

    print_section("Not a show", titles, &format_title_flag/1)
    print_section("Possible duplicates", duplicates, &format_duplicate_flag/1)

    Mix.shell().info("#{Enum.count(flags)} open #{pluralize(Enum.count(flags), "flag")}.")
  end

  defp print_section(_heading, [], _formatter), do: :ok

  defp print_section(heading, flags, formatter) do
    Mix.shell().info("#{heading} (#{Enum.count(flags)})")

    Enum.each(flags, fn flag -> Mix.shell().info("  #{formatter.(flag)}") end)

    Mix.shell().info("")
  end

  defp format_title_flag(flag) do
    "#{date(flag)}  #{flag.event.venue.name} - #{flag.event.title}  (##{flag.event.id})"
  end

  defp format_duplicate_flag(flag) do
    "#{date(flag)}  #{flag.event.venue.name} - #{flag.event.title} (##{flag.event.id})" <>
      "  ||  #{flag.related_event.venue.name} - #{flag.related_event.title} (##{flag.related_event.id})"
  end

  defp date(flag), do: DateHelpers.format_date(flag.event.date)

  defp pluralize(1, word), do: word
  defp pluralize(_count, word), do: word <> "s"
end
