defmodule MusicListingsUtilities.DateHelpers do
  @moduledoc """
  Provides Date and DateTime helpers
  """

  # Mock date is Thursday Aug 1rst, 2024
  @mock_date ~D[2024-08-01]
  @mock_time ~T[12:00:00]

  @doc """
  Wraps Date.utc_today(), returning a hard coded value when
  running in test environment
  """
  def today do
    if Application.get_env(:music_listings, :env) == :test do
      @mock_date
    else
      Date.utc_today()
    end
  end

  @doc """
  Wraps Date.utc_now(), returning a hard coded value when
  running in test environment
  """
  def now do
    if Application.get_env(:music_listings, :env) == :test do
      # Tests may override the default @mock_time via the
      # :mock_now env. Tests overriding the default need to be
      # marked as async: false
      Application.get_env(:music_listings, :mock_now) ||
        DateTime.new!(@mock_date, @mock_time, "Etc/UTC")
    else
      DateTime.utc_now(:second)
    end
  end

  @doc """
  Converts a UTC datetime to the corresponding EST datetime
  """
  @spec to_eastern_datetime(DateTime.t()) :: DateTime.t()
  def to_eastern_datetime(%DateTime{} = utc_datetime) do
    utc_datetime
    |> DateTime.shift_zone!("America/Toronto")
  end

  @doc """
  Converts a UTC datetime to the corresponding EST date
  """
  @spec to_eastern_date(DateTime.t()) :: Date.t()
  def to_eastern_date(%DateTime{} = utc_datetime) do
    utc_datetime
    |> DateTime.shift_zone!("America/Toronto")
    |> DateTime.to_date()
  end

  @doc """
  Converts a UTC datetime to the corresponding EST time
  """
  @spec to_eastern_time(DateTime.t()) :: Time.t()
  def to_eastern_time(%DateTime{} = utc_datetime) do
    utc_datetime
    |> DateTime.shift_zone!("America/Toronto")
    |> DateTime.truncate(:second)
    |> DateTime.to_time()
  end

  @doc """
  Returns today's date in Eastern time
  """
  @spec today_eastern() :: Date.t()
  def today_eastern do
    now() |> to_eastern_date()
  end

  # The hour (Eastern) at which one "night out" rolls over to the next day.  A
  # single boundary governs both when the viewer's default "today" advances
  # (`effective_today_eastern/0`) and which night a late show is attributed to
  # (`night_date/2`, `night_ordered_time_key/1`).  Set to 6am to match venue
  # close times - a 2:30am or 3:45am set is still part of the prior evening, and
  # someone still out at 4am should see it.  Stored event date/time always remain
  # the true calendar values; this is purely a listings concern.
  @night_cutoff_hour 6
  @night_cutoff_time Time.new!(@night_cutoff_hour, 0, 0)

  @doc """
  Returns the effective "today" date in Eastern time.

  Before #{@night_cutoff_hour}am Eastern, returns yesterday's date so that
  late-night users can still see the current night's events.
  """
  @spec effective_today_eastern() :: Date.t()
  def effective_today_eastern do
    eastern_datetime = now() |> to_eastern_datetime()

    if eastern_datetime.hour < @night_cutoff_hour do
      eastern_datetime |> DateTime.to_date() |> Date.add(-1)
    else
      eastern_datetime |> DateTime.to_date()
    end
  end

  @doc """
  The time-of-day before which an event counts as part of the previous night.
  Exposed so callers (e.g. SQL fragments) can share the single cutoff source.
  """
  @spec night_cutoff_time() :: Time.t()
  def night_cutoff_time, do: @night_cutoff_time

  @doc """
  The "night out" date an event belongs to: a show starting before the
  #{@night_cutoff_hour}am cutoff is attributed to the previous calendar day,
  so a 2:30am Friday set is grouped under Thursday.  Returns the true date for
  evening shows and when the time is unknown.
  """
  @spec night_date(Date.t(), Time.t() | nil) :: Date.t()
  def night_date(%Date{} = date, %Time{} = time) do
    if Time.compare(time, @night_cutoff_time) == :lt do
      Date.add(date, -1)
    else
      date
    end
  end

  def night_date(%Date{} = date, nil), do: date

  @doc """
  Builds a sort key for a `Time` that orders by "night out" rather than wall
  clock: times before #{@night_cutoff_hour}am are treated as belonging to the
  previous evening, so a 2:30am show sorts *after* an 11:30pm show rather than
  before the whole evening.  `nil` (unknown time) sorts last.
  """
  @spec night_ordered_time_key(Time.t() | nil) :: non_neg_integer()
  def night_ordered_time_key(nil), do: (24 + 24) * 60

  def night_ordered_time_key(%Time{hour: hour, minute: minute})
      when hour < @night_cutoff_hour,
      do: (hour + 24) * 60 + minute

  def night_ordered_time_key(%Time{hour: hour, minute: minute}), do: hour * 60 + minute

  def added_ago_in_words(%DateTime{} = added_at) do
    case Date.diff(effective_today_eastern(), to_eastern_date(added_at)) do
      days when days <= 0 -> "Added today"
      1 -> "Added yesterday"
      days -> "Added #{days}d ago"
    end
  end

  def format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %d %Y")
  end

  def format_date(%Date{} = date) do
    Calendar.strftime(date, "%a, %b %d %Y")
  end

  def format_time(%Time{} = time) do
    Calendar.strftime(time, "%-I:%M%p")
  end

  @doc """
  Formats a UTC datetime for display in Eastern time as a full timestamp, e.g.
  "Thursday · Aug 1, 2024 · 12:00 PM EDT". Used for "as of" headers in emails.
  """
  @spec format_eastern_datetime(DateTime.t()) :: String.t()
  def format_eastern_datetime(%DateTime{} = utc_datetime) do
    utc_datetime
    |> to_eastern_datetime()
    |> Calendar.strftime("%A · %b %-d, %Y · %-I:%M %p %Z")
  end

  @doc """
  Formats a UTC datetime for display in Eastern time as a date with year, e.g.
  "Aug 1, 2024".
  """
  @spec format_eastern_date(DateTime.t()) :: String.t()
  def format_eastern_date(%DateTime{} = utc_datetime) do
    utc_datetime
    |> to_eastern_datetime()
    |> Calendar.strftime("%b %-d, %Y")
  end

  @doc """
  Formats a UTC datetime for display in Eastern time as a month and day with no
  year, e.g. "Aug 1". Handy for compact ranges and table cells.
  """
  @spec format_eastern_day(DateTime.t()) :: String.t()
  def format_eastern_day(%DateTime{} = utc_datetime) do
    utc_datetime
    |> to_eastern_datetime()
    |> Calendar.strftime("%b %-d")
  end
end
