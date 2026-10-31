defmodule Mix.Tasks.RekeyHistoryEvents do
  @shortdoc "One-off: moves stored History events onto their Live Nation ids"

  @moduledoc """
  One-off migration for History's move from Carbonhouse to Live Nation.

  The Carbonhouse listings carried no id, so History's events were stored with
  an `external_id` built from their title and date (`kettama_2026_10_31`).
  `HistoryParser` now uses the Live Nation `discovery_id` instead, which would
  leave every stored upcoming event behind as a duplicate on the next crawl.

  Rather than deleting and recrawling - which would change the events' database
  ids and so break their `/events/:id` URLs, and drop their curation flags and
  admin locks - this rewrites each stored event's `external_id` in place.  It
  fetches History's current events from Live Nation, rebuilds the old title and
  date id for each, and re-keys the stored event that carries it.

  Soft-deleted events are re-keyed too, so a show an admin deleted stays deleted
  rather than being inserted afresh by the next crawl.

  Dry run by default: it prints what it would change and writes nothing.  Pass
  `--apply` to write.  Run it before the first crawl with the new parser; once
  it has run against production this task can be deleted.

  Usage:
    USE_PROD_DB=true mix rekey_history_events
    USE_PROD_DB=true mix rekey_history_events --apply
  """
  use Mix.Task

  import Ecto.Query

  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.VenueParsers.HistoryParser
  alias MusicListings.Repo
  alias MusicListings.Venues
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias MusicListingsUtilities.DateHelpers

  @requirements ["app.start"]

  @impl true
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [apply: :boolean])
    apply? = Keyword.get(opts, :apply, false)

    {:ok, venue} = Venues.fetch_venue_by_parser_module_name("HistoryParser")

    venue
    |> rekey(fetch_live_nation_events(), apply?)
    |> print_report(apply?)
  end

  defp fetch_live_nation_events do
    case HistoryParser.retrieve_events_fun().(HistoryParser.source_url()) do
      {:ok, %{body: body}} -> HistoryParser.events(body)
      error -> Mix.raise("Failed to fetch History's events: #{inspect(error)}")
    end
  end

  @doc """
  Re-keys `venue`'s stored events onto the ids of `live_nation_events`, writing
  only when `apply?` is true.  Returns a report of what was (or would be) done.
  """
  @spec rekey(Venue.t(), [map()], boolean()) :: map()
  def rekey(%Venue{} = venue, live_nation_events, apply?) do
    stored = venue |> stored_events() |> Map.new(&{&1.external_id, &1})

    # Two shows on one night under one name - an early and a late show - would
    # rebuild the same old id, so there is no telling which one it was.
    ambiguous_old_ids =
      live_nation_events
      |> Enum.frequencies_by(&old_id/1)
      |> Enum.filter(fn {_old_id, count} -> count > 1 end)
      |> MapSet.new(fn {old_id, _count} -> old_id end)

    results =
      Enum.map(live_nation_events, fn live_nation_event ->
        classify(live_nation_event, stored, ambiguous_old_ids)
      end)

    if apply?, do: Repo.transaction(fn -> Enum.each(results, &apply_result/1) end)

    touched_ids =
      Enum.flat_map(results, fn
        {:rekey, event, new_id} -> [event.external_id, new_id]
        {_status, _event, new_id} -> [new_id]
      end)

    %{
      results: Enum.group_by(results, &elem(&1, 0)),
      unmatched: unmatched_upcoming(Map.values(stored), touched_ids)
    }
  end

  defp apply_result({:rekey, event, new_id}) do
    event
    |> Ecto.Changeset.change(external_id: new_id)
    |> Repo.update!()
  end

  defp apply_result(_result), do: :ok

  defp classify(live_nation_event, stored, ambiguous_old_ids) do
    old_id = old_id(live_nation_event)
    new_id = HistoryParser.event_id(live_nation_event)

    cond do
      Map.has_key?(stored, new_id) and Map.has_key?(stored, old_id) ->
        {:conflict, stored[old_id], new_id}

      Map.has_key?(stored, new_id) ->
        {:already_rekeyed, stored[new_id], new_id}

      MapSet.member?(ambiguous_old_ids, old_id) ->
        {:ambiguous, stored[old_id], new_id}

      Map.has_key?(stored, old_id) ->
        {:rekey, stored[old_id], new_id}

      true ->
        {:new, nil, new_id}
    end
  end

  defp old_id(live_nation_event) do
    live_nation_event
    |> HistoryParser.event_title()
    |> ParseHelpers.build_id_from_title_and_date(HistoryParser.event_date(live_nation_event))
  end

  defp stored_events(venue) do
    from(event in Event, where: event.venue_id == ^venue.id)
    |> Repo.all()
  end

  # Upcoming, live events the crawl will no longer update - most likely a show
  # Live Nation lists under a different name than the old site did.
  defp unmatched_upcoming(stored_events, touched_ids) do
    today = DateHelpers.today_eastern()

    stored_events
    |> Enum.filter(fn event ->
      is_nil(event.deleted_at) and Date.compare(event.date, today) != :lt and
        event.external_id not in touched_ids
    end)
    |> Enum.sort_by(& &1.date, Date)
  end

  defp print_report(%{results: results, unmatched: unmatched}, apply?) do
    shell = Mix.shell()

    if apply?,
      do: shell.info("Applied.\n"),
      else: shell.info("Dry run - nothing written.\n")

    print_section("Re-keyed", results[:rekey], fn {:rekey, event, new_id} ->
      "#{event.date}  #{event.external_id} -> #{new_id}  (event #{event.id})"
    end)

    print_section("Already on their Live Nation id", results[:already_rekeyed], fn
      {_status, event, new_id} -> "#{event.date}  #{new_id}  (event #{event.id})"
    end)

    print_section(
      "Skipped - stored under both ids, resolve by hand",
      results[:conflict],
      fn {_status, event, new_id} ->
        "#{event.date}  #{event.external_id} and #{new_id}  (event #{event.id})"
      end
    )

    print_section(
      "Skipped - more than one show rebuilds this old id",
      results[:ambiguous],
      fn {_status, event, new_id} ->
        old = if event, do: "#{event.external_id} (event #{event.id})", else: "no stored event"
        "#{new_id}  #{old}"
      end
    )

    shell.info("Not stored yet (the next crawl inserts them): #{length(results[:new] || [])}\n")

    print_section(
      "Upcoming stored events no Live Nation event matched (check for duplicates)",
      unmatched,
      fn event -> "#{event.date}  #{event.external_id}  #{event.title}  (event #{event.id})" end
    )
  end

  defp print_section(_heading, nil, _format), do: :ok
  defp print_section(_heading, [], _format), do: :ok

  defp print_section(heading, rows, format) do
    Mix.shell().info("#{heading} (#{length(rows)}):")
    Enum.each(rows, &Mix.shell().info("  " <> format.(&1)))
    Mix.shell().info("")
  end
end
