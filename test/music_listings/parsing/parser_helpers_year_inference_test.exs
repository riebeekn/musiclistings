defmodule MusicListings.Parsing.ParserHelpersYearInferenceTest do
  # async: false - these tests override the global :mock_today config, so this
  # module must not run alongside other tests.
  use ExUnit.Case, async: false

  alias MusicListings.Parsing.ParseHelpers

  describe "build_date_from_month_day_strings/2" do
    setup do
      on_exit(fn -> Application.delete_env(:music_listings, :mock_today) end)
    end

    defp today_is(date), do: Application.put_env(:music_listings, :mock_today, date)

    test "assumes the current year for a date around today" do
      today_is(~D[2026-08-11])

      assert {:ok, ~D[2026-09-20]} == ParseHelpers.build_date_from_month_day_strings("Sep", "20")
      assert {:ok, ~D[2026-08-01]} == ParseHelpers.build_date_from_month_day_strings("Aug", "1")
    end

    test "rolls forward for a date well in the past" do
      today_is(~D[2026-08-11])

      # A January listing seen in August is next January, not the one gone by
      assert {:ok, ~D[2027-01-16]} == ParseHelpers.build_date_from_month_day_strings("Jan", "16")
    end

    test "tolerates a listing that lingers a few weeks after the show" do
      today_is(~D[2026-08-11])

      assert {:ok, ~D[2026-07-20]} == ParseHelpers.build_date_from_month_day_strings("Jul", "20")
    end

    test "rolls back a December listing still up in the new year" do
      # New Year's Day, with the venue's page still showing the week just gone.
      # Read as the December ahead, these become phantom events a year out; the
      # right answer is the December behind, which the crawler then drops as past.
      today_is(~D[2026-01-01])

      assert {:ok, ~D[2025-12-26]} == ParseHelpers.build_date_from_month_day_strings("Dec", "26")
      assert {:ok, ~D[2025-12-31]} == ParseHelpers.build_date_from_month_day_strings("Dec", "31")
    end

    test "still reads a genuinely upcoming date as this year in early January" do
      today_is(~D[2026-01-01])

      assert {:ok, ~D[2026-01-16]} == ParseHelpers.build_date_from_month_day_strings("Jan", "16")
      assert {:ok, ~D[2026-10-31]} == ParseHelpers.build_date_from_month_day_strings("Oct", "31")
      # The far edge of the window, 330 days out
      assert {:ok, ~D[2026-11-27]} == ParseHelpers.build_date_from_month_day_strings("Nov", "27")
    end

    test "maps every month/day to exactly one date, whichever end it comes from" do
      today_is(~D[2026-01-01])

      # A year wide window: the day past the forward edge is the same day the
      # backward rule would roll forward, so no date has two answers
      assert {:ok, ~D[2025-11-28]} == ParseHelpers.build_date_from_month_day_strings("Nov", "28")

      today_is(~D[2026-11-29])

      assert {:ok, ~D[2026-11-28]} == ParseHelpers.build_date_from_month_day_strings("Nov", "28")
    end

    test "returns an error when a shifted date does not exist" do
      today_is(~D[2024-08-01])

      assert {:error, :invalid_date} ==
               ParseHelpers.build_date_from_month_day_strings("Feb", "29")
    end
  end
end
