defmodule MusicListings.Curation do
  @moduledoc """
  Flags upcoming listings that look wrong, for a human to judge.

  Crawling a venue's calendar picks up whatever that calendar publishes, which
  is not always a show.  Two problems recur often enough to be worth catching
  automatically:

    * **Non-event titles.**  A venue posts its closures and private hires to the
      same calendar as its gigs - "CLOSED MONDAY - WEDNESDAY", "Private
      Booking", "PRIVATE EVENT".

    * **Duplicates on one date.**  Either the same venue listed twice (an
      `external_id` format change leaves the old row behind, so
      `sara_bareilles_2026_09_15` and `sara_bareilles_2026_09_15_2026-09-15` are
      both live), or one room crawled through two venues - The Dance Cave is
      upstairs at Lee's Palace and both parsers publish the same show, as "Slow
      Teeth w/ Waxlimbs" and "Slow Teeth with Waxlimbs".

  Nothing here deletes anything.  `run/0` records what looks suspect, the crawl
  summary email lists it, and an admin decides.  The rules are therefore tuned
  for precision over recall: a queue that cries wolf stops being read, and a
  missed listing costs far less than a deleted real one.

  ## Why flags are persisted

  Some flagged events are genuinely fine - a festival really does run at four
  venues on one night.  Recomputing the report each crawl would surface those
  forever.  Instead flags are rows, `dismiss_flags/2` sets `dismissed_at`, and
  `run/0` never resurrects a dismissed flag.  The queue drains.
  """
  import Ecto.Query

  alias MusicListings.Accounts.User
  alias MusicListings.Repo
  alias MusicListings.TitleSimilarity
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.EventFlag
  alias MusicListingsUtilities.DateHelpers

  require Logger

  # Titles that describe the venue's state rather than a performance.  Kept
  # deliberately narrow: a broader sweep also matches karaoke, trivia, open mic
  # and holiday listings, which are real events we want to keep.
  @non_event_title_patterns [
    ~r/\bclosed\b/i,
    ~r/\bprivate (event|booking|function|party|rental|show)\b/i,
    ~r/\b(venue|hall|room) rental\b/i
  ]

  # Placeholders, but only when they are the whole title - "Open Stage - TBA" is
  # a real recurring night.
  @placeholder_titles ~w(tba tbd n/a test)

  # Title similarity at which two listings on one date are worth a second look.
  # Independent of the affiliate matcher's threshold: that one guards against
  # publishing a wrong ticket link, this one only costs a glance.
  @duplicate_threshold 0.85

  @type flag_counts :: %{non_event_title: non_neg_integer(), duplicate_event: non_neg_integer()}

  @doc """
  Recomputes flags over all upcoming events and reconciles them with what is
  already recorded.

  Returns the counts of currently open flags by type.

  Three-way reconciliation, so that the queue reflects the data as it stands
  now without losing an admin's decisions:

    * flags that are new are inserted (`on_conflict: :nothing`, so re-running is
      idempotent and a dismissed flag is never resurrected);
    * open flags that no longer reproduce are deleted, so correcting a title
      clears it from the queue;
    * dismissed flags are left strictly alone.
  """
  @spec run :: flag_counts()
  def run do
    events = upcoming_events()
    current = detect(events)

    Repo.insert_all(EventFlag, Enum.map(current, &insertable/1), on_conflict: :nothing)
    delete_stale_open_flags(current)

    open_flag_counts()
  end

  @doc """
  Runs the analysis, logging rather than raising on failure.

  The nightly crawl calls this: a curation bug must not cost the crawl summary
  email, and because flags are persisted the previous run's queue is still
  reported if this one fails.
  """
  @spec run_quietly :: flag_counts() | {:error, term()}
  def run_quietly do
    run()
  rescue
    error ->
      Logger.error("Curation run crashed: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Open flags for the review queue, most imminent event first.

  A flag is open when it has not been dismissed, its event is still upcoming and
  not deleted, and - for a duplicate pair - the other side is not deleted
  either.  Deleting either event therefore resolves the pair with no extra
  bookkeeping.
  """
  @spec list_open_flags :: [EventFlag.t()]
  def list_open_flags do
    today = DateHelpers.today_eastern()

    EventFlag
    |> where([flag], is_nil(flag.dismissed_at))
    |> join(:inner, [flag], event in assoc(flag, :event))
    |> where([_flag, event], is_nil(event.deleted_at) and event.date >= ^today)
    |> join(:left, [flag], related in assoc(flag, :related_event))
    |> where(
      [flag, _event, related],
      is_nil(flag.related_event_id) or is_nil(related.deleted_at)
    )
    |> order_by([_flag, event], asc: event.date, asc: event.title)
    |> preload([_flag, event, related], event: {event, :venue}, related_event: {related, :venue})
    |> Repo.all()
  end

  @doc """
  Whether an event has any open flag, as either side of a pair.
  """
  @spec flagged?(pos_integer()) :: boolean()
  def flagged?(event_id) do
    EventFlag
    |> where([flag], is_nil(flag.dismissed_at))
    |> where([flag], flag.event_id == ^event_id or flag.related_event_id == ^event_id)
    |> Repo.exists?()
  end

  @doc """
  Marks every open flag touching this event as judged-fine.  Admin only.

  Dismisses on both sides of a pair, since a duplicate that turns out to be two
  genuinely different shows is settled for both of them at once.
  """
  @spec dismiss_flags(User | nil, pos_integer()) ::
          {:ok, non_neg_integer()} | {:error, :not_allowed}
  def dismiss_flags(%User{role: :admin}, event_id) do
    {count, _returned} =
      EventFlag
      |> where([flag], is_nil(flag.dismissed_at))
      |> where([flag], flag.event_id == ^event_id or flag.related_event_id == ^event_id)
      |> Repo.update_all(set: [dismissed_at: DateHelpers.now(), updated_at: DateHelpers.now()])

    {:ok, count}
  end

  def dismiss_flags(_user, _event_id), do: {:error, :not_allowed}

  # A flag is identified by the triple the unique indexes are built on.
  defp key(%{event_id: event_id, type: type, related_event_id: related_event_id}) do
    {event_id, type, related_event_id}
  end

  defp insertable(flag) do
    now = DateHelpers.now()

    flag
    |> Map.take([:event_id, :related_event_id, :type, :reason])
    |> Map.merge(%{inserted_at: now, updated_at: now})
  end

  # Open flags whose cause has gone - a title was fixed, or one of a pair was
  # re-titled.  Dismissed flags are excluded: removing one would let `run/0`
  # insert it again on the next crawl, undoing the admin's decision.
  defp delete_stale_open_flags(current) do
    current_keys = MapSet.new(current, &key/1)

    stale_ids =
      EventFlag
      |> where([flag], is_nil(flag.dismissed_at))
      |> select([flag], {flag.id, flag.event_id, flag.type, flag.related_event_id})
      |> Repo.all()
      |> Enum.reject(fn {_id, event_id, type, related_event_id} ->
        MapSet.member?(current_keys, {event_id, type, related_event_id})
      end)
      |> Enum.map(fn {id, _event_id, _type, _related_event_id} -> id end)

    EventFlag
    |> where([flag], flag.id in ^stale_ids)
    |> Repo.delete_all()
  end

  defp open_flag_counts do
    counts =
      list_open_flags()
      |> Enum.frequencies_by(& &1.type)

    %{
      non_event_title: Map.get(counts, :non_event_title, 0),
      duplicate_event: Map.get(counts, :duplicate_event, 0)
    }
  end

  defp upcoming_events do
    today = DateHelpers.today_eastern()

    Event
    |> where([event], is_nil(event.deleted_at) and event.date >= ^today)
    |> join(:inner, [event], venue in assoc(event, :venue))
    |> preload([_event, venue], venue: venue)
    |> Repo.all()
  end

  defp detect(events) do
    non_event_title_flags(events) ++ duplicate_flags(events)
  end

  defp non_event_title_flags(events) do
    events
    |> Enum.filter(&non_event_title?(&1.title))
    |> Enum.map(fn event ->
      %{
        event_id: event.id,
        related_event_id: nil,
        type: :non_event_title,
        reason: "Title looks like a venue status rather than a show"
      }
    end)
  end

  defp non_event_title?(nil), do: false

  defp non_event_title?(title) do
    placeholder_title?(title) or Enum.any?(@non_event_title_patterns, &Regex.match?(&1, title))
  end

  defp placeholder_title?(title) do
    normalized = title |> String.trim() |> String.downcase()

    normalized in @placeholder_titles
  end

  # Only events sharing a date and a building are compared.  Restricting it this
  # far is what keeps the queue readable: comparing across all venues surfaces
  # every multi-venue festival as a pile of false pairs.
  defp duplicate_flags(events) do
    events
    |> Enum.group_by(&{&1.date, venue_group_key(&1.venue)})
    |> Enum.flat_map(fn {_key, grouped} -> duplicate_pairs(grouped) end)
  end

  defp duplicate_pairs(events) do
    for left <- events,
        right <- events,
        left.id < right.id,
        not showtimes_conflict?(left.title, right.title),
        TitleSimilarity.score(left.title, right.title) >= @duplicate_threshold do
      # The flag hangs off the higher id so a pair produces one row, not two.
      %{
        event_id: right.id,
        related_event_id: left.id,
        type: :duplicate_event,
        reason: duplicate_reason(left, right)
      }
    end
  end

  # Two houses on one night are two listings, not a duplicate - "Northern Lights
  # - 4:30pm Show" and "- 7:30 show" are both real.
  #
  # `TitleSimilarity` has its own number guard, but it runs on the normalized
  # string, and normalization drops everything after the first ":" or " - " when
  # what precedes it is substantial.  That takes the showtime with it, leaving
  # the two titles identical.  Comparing the raw titles catches what that trim
  # hides.  Only applied when both sides carry numbers, so a tour year on one
  # side alone ("PROJECT NOWHERE 2026" vs "PROJECT NOWHERE IV") still pairs.
  defp showtimes_conflict?(left, right) do
    left_numbers = title_numbers(left)
    right_numbers = title_numbers(right)

    left_numbers != [] and right_numbers != [] and left_numbers != right_numbers
  end

  defp title_numbers(nil), do: []

  defp title_numbers(title) do
    ~r/\d+/
    |> Regex.scan(title)
    |> List.flatten()
    |> Enum.sort()
  end

  defp duplicate_reason(%{venue_id: venue_id}, %{venue_id: venue_id}) do
    "Listed twice at this venue on the same date"
  end

  defp duplicate_reason(left, right) do
    "Also listed on this date at #{left.venue.name} / #{right.venue.name}"
  end

  @doc """
  Groups venues that share a building, so a show crawled through two of them is
  seen as one listing.

  Derived from the street address rather than configured, because the venues
  that need it are already in the data: The Dance Cave is upstairs at Lee's
  Palace, TD Music Hall is inside Massey Hall, and the Royal Conservatory has
  three halls at one address.

  The key is the street number plus the first word of the street name, which
  survives the abbreviations that stop the raw strings matching - "529 Bloor St
  W" and "529 Bloor Street West" both key to `529 bloor`.

  Postal code was tried first and is wrong in both directions: the four
  Exhibition Place venues share `M6K 3C3` while being genuinely separate rooms,
  and Hard Luck Bar and Wiggle Room share a building on different postal codes.
  """
  @spec venue_group_key(map()) :: String.t()
  def venue_group_key(%{street: street}) when is_binary(street) do
    normalized = street |> String.downcase() |> String.trim()

    case Regex.run(~r/^(\d+)\s*(\S+)/u, normalized) do
      [_match, number, name] -> "#{number} #{name}"
      # No leading street number to key on - fall back to the whole address so
      # the venue only ever groups with itself.
      nil -> normalized
    end
  end

  def venue_group_key(%{id: id}), do: "venue-#{id}"
end
