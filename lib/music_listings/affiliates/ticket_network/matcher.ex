defmodule MusicListings.Affiliates.TicketNetwork.Matcher do
  @moduledoc """
  Matches TicketNetwork catalog items to our events.

  ## The day offset

  TicketNetwork's `LaunchDate` runs exactly a day behind the real event date, so
  an item is only ever compared against events on `LaunchDate + 1`.

  The offset is uniform, not approximate.  Measured against a live catalog: of
  the items with a single unambiguous title match at their venue anywhere within
  a four-day window, every one sat a day ahead of `LaunchDate`.  The apparent
  exceptions were second-night products of a run, not a different offset.

  A fixed offset is what makes consecutive nights matchable - see below - and a
  wrong date still cannot produce a match on its own, since the title has to
  clear `@threshold` as well.

  The item's *time* is never used - TicketNetwork only ever reports 19:00 or
  20:00, and those disagree with the venue's real start time more often than
  they agree.

  ## Precision over recall

  A wrong affiliate link is worse than no affiliate link, so a match is only
  accepted when it is unambiguous:

    * the title similarity must reach `@threshold`, and
    * exactly one of our events on that night may reach it - ties are skipped
      rather than guessed between.

  ## Consecutive-night runs

  Runs of identically titled shows on consecutive nights - a symphony programme
  repeated over four evenings, a two-night stand by the same band - are matched
  like anything else.  With a single offset each catalog item resolves to one
  night and one night only, and TicketNetwork lists a separate product per
  night, so the nights of a run map onto the products one for one.

  They are still worth watching, because a run is where a mis-dated item would
  do damage silently: the titles are identical, so an item that landed on the
  wrong night would match it just as convincingly.  Runs are therefore reported
  in `t:result/0` for a spot check, without being held back from matching.
  """
  alias MusicListings.Affiliates.TicketNetwork.Item
  alias MusicListings.TitleSimilarity

  @date_offset 1

  @threshold 0.85

  @type match :: %{
          event_id: pos_integer(),
          url: String.t(),
          score: float(),
          catalog_item_id: String.t(),
          item_name: String.t()
        }

  @type consecutive_run :: %{venue_id: pos_integer(), title: String.t(), dates: [Date.t()]}

  @type result :: %{
          matches: [match()],
          consecutive_runs: [consecutive_run()],
          unmatched_items: [Item.t()],
          untracked_labels: %{String.t() => pos_integer()}
        }

  @doc """
  Matches catalog items against events.

  `venue_ids` maps a `parser_module_name` onto a venue id, letting the caller
  resolve TicketNetwork's venue labels without this module touching the
  database.
  """
  @spec match([Item.t()], [struct()], %{String.t() => pos_integer()}) :: result()
  def match(items, events, venue_ids) do
    events_by_venue_and_date = Enum.group_by(events, &{&1.venue_id, &1.date})

    {matches, unmatched_items, untracked_labels} =
      Enum.reduce(items, {[], [], %{}}, fn item, acc ->
        reduce_item(item, acc, venue_ids, events_by_venue_and_date)
      end)

    %{
      matches: dedupe_matches(matches),
      consecutive_runs: consecutive_runs(events),
      unmatched_items: Enum.reverse(unmatched_items),
      untracked_labels: untracked_labels
    }
  end

  @doc """
  Reduces a title to its identifying words.  See
  `MusicListings.TitleSimilarity.normalize/1`.
  """
  @spec normalize(String.t() | nil) :: String.t()
  defdelegate normalize(title), to: TitleSimilarity

  @doc """
  Similarity of two titles, from 0.0 to 1.0.  See
  `MusicListings.TitleSimilarity.score/2`.
  """
  @spec score(String.t() | nil, String.t() | nil) :: float()
  defdelegate score(left, right), to: TitleSimilarity

  @doc """
  The similarity a match must reach to be accepted.
  """
  @spec threshold :: float()
  def threshold, do: @threshold

  defp reduce_item(item, {matches, unmatched, untracked}, venue_ids, events_by_venue_and_date) do
    case venue_id_for(item, venue_ids) do
      nil ->
        {matches, unmatched, Map.update(untracked, item.venue_label, 1, &(&1 + 1))}

      venue_id ->
        case best_match(item, venue_id, events_by_venue_and_date) do
          nil -> {matches, [item | unmatched], untracked}
          match -> {[match | matches], unmatched, untracked}
        end
    end
  end

  defp venue_id_for(item, venue_ids) do
    case Item.parser_module_name(item) do
      nil -> nil
      parser_module_name -> Map.get(venue_ids, parser_module_name)
    end
  end

  defp best_match(item, venue_id, events_by_venue_and_date) do
    date = Date.add(item.date, @date_offset)

    events_by_venue_and_date
    |> Map.get({venue_id, date}, [])
    |> unambiguous_best(item)
    |> case do
      nil ->
        nil

      {event, score} ->
        %{
          event_id: event.id,
          url: item.url,
          score: score,
          catalog_item_id: item.catalog_item_id,
          item_name: item.name
        }
    end
  end

  # Returns the single best-scoring event, or nil when nothing clears the
  # threshold or when two events tie for the lead.
  defp unambiguous_best(events, item) do
    events
    |> Enum.map(&{&1, event_score(&1, item)})
    |> Enum.filter(fn {_event, score} -> score >= @threshold end)
    |> Enum.sort_by(fn {_event, score} -> score end, :desc)
    |> case do
      [{event, score}] -> {event, score}
      [{event, score}, {_runner_up, lower} | _rest] when score > lower -> {event, score}
      _tied_or_empty -> nil
    end
  end

  # An event's title, headliner and openers are all fair game - TicketNetwork
  # frequently names the headliner where we store a fuller bill.
  defp event_score(event, item) do
    [event.title, event.headliner | event.openers || []]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&score(item.name, &1))
    |> Enum.max(fn -> 0.0 end)
  end

  # TicketNetwork sometimes lists one event as several catalog products.  Keep
  # the strongest match, breaking ties on catalog item id so runs are stable.
  defp dedupe_matches(matches) do
    matches
    |> Enum.group_by(& &1.event_id)
    |> Enum.map(fn {_event_id, candidates} ->
      Enum.min_by(candidates, &{-&1.score, &1.catalog_item_id})
    end)
    |> Enum.sort_by(& &1.event_id)
  end

  # Only the nights that actually abut another night of the same show belong to
  # a run.  A residency with an isolated date months later reports the abutting
  # nights alone, since that lone date carries none of the risk a run does.
  defp consecutive_runs(events) do
    events
    |> Enum.group_by(&{&1.venue_id, normalize(&1.title)})
    |> Enum.reject(fn {{_venue_id, normalized}, _group} -> normalized == "" end)
    |> Enum.flat_map(fn {{venue_id, _normalized}, group} ->
      case adjacent_dates(group) do
        [] ->
          []

        dates ->
          [%{venue_id: venue_id, title: group |> List.first() |> Map.get(:title), dates: dates}]
      end
    end)
    |> Enum.sort_by(&{&1.venue_id, &1.title})
  end

  defp adjacent_dates(events) do
    dates = events |> Enum.map(& &1.date) |> Enum.uniq()
    date_set = MapSet.new(dates)

    dates
    |> Enum.filter(fn date ->
      MapSet.member?(date_set, Date.add(date, -1)) or MapSet.member?(date_set, Date.add(date, 1))
    end)
    |> Enum.sort(Date)
  end
end
