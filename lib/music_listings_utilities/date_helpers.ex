defmodule MusicListingsUtilities.DateHelpers do
  @moduledoc """
  Provides Date and DateTime helpers
  """

  # Mock date is Thursday Aug 1rst, 2024
  @mock_date ~D[2024-08-01]
  @mock_time ~T[00:00:00.000000]

  def today do
    if Application.get_env(:music_listings, :env) == :test do
      @mock_date
    else
      Date.utc_today()
    end
  end

  def now do
    if Application.get_env(:music_listings, :env) == :test do
      DateTime.new!(@mock_date, @mock_time, "Etc/UTC")
    else
      DateTime.utc_now()
    end
  end

  def utc_to_eastern_date(%DateTime{} = utc_datetime) do
    utc_datetime
    |> DateTime.shift_zone!("America/Toronto")
    |> DateTime.to_date()
  end

  def utc_to_eastern_time(%DateTime{} = utc_datetime) do
    utc_datetime
    |> DateTime.shift_zone!("America/Toronto")
    |> DateTime.truncate(:second)
    |> DateTime.to_time()
  end
end
