defmodule MusicListingsUtilities.DateHelpers do
  @moduledoc """
  Provides Date and DateTime helpers
  """

  # Mock date is Thursday Aug 1rst, 2024
  @mock_date ~D[2024-08-01]
  @mock_time ~T[00:00:00]

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

  def format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%b %d %Y")
  end

  def format_date(%Date{} = date) do
    Calendar.strftime(date, "%a, %b %d %Y")
  end

  def format_time(%Time{} = time) do
    ~D[2000-01-01]
    |> DateTime.new!(time)
    |> Calendar.strftime("%-I:%M%p")
  end
end
