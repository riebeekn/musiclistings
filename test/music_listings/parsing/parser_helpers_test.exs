defmodule MusicListings.Parsing.ParserHelpersTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.ParseHelpers

  describe "convert_event_time_string_to_time/1" do
    test "return nil with invalid time string" do
      assert nil == ParseHelpers.convert_event_time_string_to_time("bob")
    end

    test "converts valid time strings" do
      assert ~T[07:30:00] == ParseHelpers.convert_event_time_string_to_time("07:30")
      assert ~T[19:30:00] == ParseHelpers.convert_event_time_string_to_time("7:30pm")
    end
  end

  describe "convert_age_restriction_string_to_enum/1" do
    test "converts valid all ages strings" do
      assert :all_ages == ParseHelpers.convert_age_restriction_string_to_enum("All")
      assert :all_ages == ParseHelpers.convert_age_restriction_string_to_enum("All ages event")
      assert :all_ages == ParseHelpers.convert_age_restriction_string_to_enum("All Ages")
    end

    test "converts valid 19+ strings" do
      assert :nineteen_plus == ParseHelpers.convert_age_restriction_string_to_enum("19+")
      assert :nineteen_plus == ParseHelpers.convert_age_restriction_string_to_enum("19+ event")
    end
  end
end
