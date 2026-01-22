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
      assert {:ok, ~D[2014-12-18]} ==
               ParseHelpers.build_date_from_year_month_day_strings(
                 " 2014, ",
                 "DECEMBER",
                 " 18th  "
               )
    end

    test "returns error for invalid date" do
      assert {:error, :invalid_date} ==
               ParseHelpers.build_date_from_year_month_day_strings("2014", "NOTAMONTH", "18")
    end
  end

  describe "build_date_from_month_day_strings/2" do
    test "parses month and day strings" do
      # The function infers the year based on today's date
      assert {:ok, date} = ParseHelpers.build_date_from_month_day_strings("JAN", "1st")
      assert date.month == 1
      assert date.day == 1
    end

    test "returns error for invalid date" do
      assert {:error, :invalid_date} ==
               ParseHelpers.build_date_from_month_day_strings("NOTAMONTH", "1st")
    end
  end

  describe "parse_day_month_day_string/1" do
    test "parses valid day, month day format" do
      assert {:ok, _date} = ParseHelpers.parse_day_month_day_string("Friday, January 23")
    end

    test "returns error for invalid format" do
      assert {:error, :invalid_date} == ParseHelpers.parse_day_month_day_string("Invalid string")
    end
  end

  describe "build_time_from_time_string/1" do
    test "returns error with invalid time string" do
      assert {:error, :invalid_time} == ParseHelpers.build_time_from_time_string("bob")
    end

    test "returns error when fail to create time string" do
      assert {:error, :invalid_time} == ParseHelpers.build_time_from_time_string("630pm")
    end

    test "returns error for nil" do
      assert {:error, :invalid_time} == ParseHelpers.build_time_from_time_string(nil)
    end

    test "converts valid time strings" do
      assert {:ok, ~T[07:30:00]} == ParseHelpers.build_time_from_time_string("07:30")
      assert {:ok, ~T[19:30:00]} == ParseHelpers.build_time_from_time_string("7:30pm")
    end
  end
end
