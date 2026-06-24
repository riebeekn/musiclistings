defmodule MusicListingsUtilities.DateHelpersTest do
  # async: false - the effective_today_eastern/0 tests override the global
  # :mock_now config, so this module must not run alongside other tests.
  use ExUnit.Case, async: false

  alias MusicListingsUtilities.DateHelpers

  describe "effective_today_eastern/0" do
    setup do
      on_exit(fn -> Application.delete_env(:music_listings, :mock_now) end)
    end

    test "after the 6am cutoff, returns the current Eastern day" do
      # 7:00am Eastern (11:00 UTC, EDT)
      Application.put_env(
        :music_listings,
        :mock_now,
        DateTime.new!(~D[2024-08-02], ~T[11:00:00], "Etc/UTC")
      )

      assert ~D[2024-08-02] == DateHelpers.effective_today_eastern()
    end

    test "before the 6am cutoff, returns the previous day (night still in progress)" do
      # 2:30am Eastern (06:30 UTC, EDT)
      Application.put_env(
        :music_listings,
        :mock_now,
        DateTime.new!(~D[2024-08-02], ~T[06:30:00], "Etc/UTC")
      )

      assert ~D[2024-08-01] == DateHelpers.effective_today_eastern()
    end

    test "between 3am and 6am Eastern, still returns the previous day (6am boundary, not 3am)" do
      # 4:00am Eastern (08:00 UTC, EDT)
      Application.put_env(
        :music_listings,
        :mock_now,
        DateTime.new!(~D[2024-08-02], ~T[08:00:00], "Etc/UTC")
      )

      assert ~D[2024-08-01] == DateHelpers.effective_today_eastern()
    end
  end

  describe "night_date/2" do
    test "attributes a pre-dawn show to the previous day" do
      assert ~D[2024-08-01] == DateHelpers.night_date(~D[2024-08-02], ~T[02:30:00])
    end

    test "leaves evening shows on their calendar day" do
      assert ~D[2024-08-02] == DateHelpers.night_date(~D[2024-08-02], ~T[20:00:00])
    end

    test "leaves shows with an unknown time on their calendar day" do
      assert ~D[2024-08-02] == DateHelpers.night_date(~D[2024-08-02], nil)
    end
  end

  describe "night_ordered_time_key/1" do
    test "orders pre-dawn times after late-evening times" do
      late_evening = DateHelpers.night_ordered_time_key(~T[23:30:00])
      pre_dawn = DateHelpers.night_ordered_time_key(~T[02:30:00])

      assert late_evening < pre_dawn
    end

    test "orders evening times in clock order" do
      assert DateHelpers.night_ordered_time_key(~T[17:30:00]) <
               DateHelpers.night_ordered_time_key(~T[20:00:00])
    end

    test "orders an unknown (nil) time last" do
      assert DateHelpers.night_ordered_time_key(~T[02:30:00]) <
               DateHelpers.night_ordered_time_key(nil)
    end

    test "sorts a full night in night-out order" do
      times = [~T[02:30:00], ~T[17:30:00], ~T[23:30:00], ~T[20:00:00]]

      assert [~T[17:30:00], ~T[20:00:00], ~T[23:30:00], ~T[02:30:00]] ==
               Enum.sort_by(times, &DateHelpers.night_ordered_time_key/1)
    end
  end
end
