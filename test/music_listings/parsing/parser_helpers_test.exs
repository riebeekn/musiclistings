defmodule MusicListings.Parsing.ParserHelpersTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.ParseHelpers

  describe "build_id_from_title_and_date/2" do
    test "replaces punctuation and spaces" do
      assert "some_event_2024_12_14" ==
               ParseHelpers.build_id_from_title_and_date("some|-*&'#  event", ~D[2024-12-14])
    end

    test "replaces cancelled" do
      assert "some_event_2024_12_14" ==
               ParseHelpers.build_id_from_title_and_date(
                 "some-*&cancelled'#  event",
                 ~D[2024-12-14]
               )
    end
  end

  describe "age_restriction_string_to_enum/1" do
    test "converts valid all ages strings" do
      assert :all_ages == ParseHelpers.age_restriction_string_to_enum("All")
      assert :all_ages == ParseHelpers.age_restriction_string_to_enum("All ages event")
      assert :all_ages == ParseHelpers.age_restriction_string_to_enum("All Ages")
    end

    test "converts valid 18+ strings" do
      assert :eighteen_plus == ParseHelpers.age_restriction_string_to_enum("18+")
    end

    test "converts valid 19+ strings" do
      assert :nineteen_plus == ParseHelpers.age_restriction_string_to_enum("19+")
      assert :nineteen_plus == ParseHelpers.age_restriction_string_to_enum("19+ event")
    end
  end

  describe "build_date_from_year_month_day_strings/3" do
    test "builds a date" do
      assert ~D[2014-12-18] ==
               ParseHelpers.build_date_from_year_month_day_strings(
                 " 2014, ",
                 "DECEMBER",
                 " 18th  "
               )
    end
  end

  describe "build_date_from_month_day_strings/2" do
    test "when date in the past increments the year by 1" do
      assert ~D[2025-01-01] == ParseHelpers.build_date_from_month_day_strings("JAN", "1st")
    end
  end

  describe "build_time_from_time_string/1" do
    test "return nil with invalid time string" do
      assert nil == ParseHelpers.build_time_from_time_string("bob")
    end

    test "return nil when fail to create time string" do
      assert nil == ParseHelpers.build_time_from_time_string("630pm")
    end

    test "converts valid time strings" do
      assert ~T[07:30:00] == ParseHelpers.build_time_from_time_string("07:30")
      assert ~T[19:30:00] == ParseHelpers.build_time_from_time_string("7:30pm")
    end
  end
end
