defmodule MusicListings.Parsing.VenueParsers.ArraymusicParser.DateParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.VenueParsers.ArraymusicParser.DateParser

  describe "parse_dates/2" do
    test "parses single date format" do
      assert %DateParser{date: ~D[2025-02-15], additional_dates: []} ==
               DateParser.parse_dates("event title", "February 15, 2025 @ 8:00 pm ET")
    end

    test "parses multiple date format with years in title" do
      assert %DateParser{
               date: ~D[2024-09-26],
               additional_dates: [
                 ~D[2024-10-31],
                 ~D[2024-11-28],
                 ~D[2025-01-30],
                 ~D[2025-02-27],
                 ~D[2025-03-27],
                 ~D[2025-04-24],
                 ~D[2025-05-29],
                 ~D[2025-06-26]
               ]
             } ==
               DateParser.parse_dates(
                 "CCMC Event Extra 24|25",
                 "Sep 26 • Oct 31 • Nov 28 • Jan 30 • Feb 27 • Mar 27 • Apr 24 • May 29 • Jun 26 @ 7:30 pm ET"
               )
    end

    test "parse multiple date format with year in first date" do
      assert %DateParser{
               date: ~D[2025-01-20],
               additional_dates: [
                 ~D[2025-02-17],
                 ~D[2025-03-17],
                 ~D[2025-04-27],
                 ~D[2025-05-19],
                 ~D[2025-06-16]
               ]
             } ==
               DateParser.parse_dates(
                 "event title",
                 "Jan 20, 2025 • Feb 17 • Mar 17 • Apr 27 • May 19 • June 16 @ 7:00 pm ET"
               )
    end

    test "returns nil on single date without a year" do
      assert %DateParser{date: nil, additional_dates: []} ==
               DateParser.parse_dates("event title", "Nov 1 @ 8:00 pm ET")
    end

    test "returns nil on 2 dates without a year" do
      assert %DateParser{date: nil, additional_dates: []} ==
               DateParser.parse_dates(
                 "event title",
                 "Nov 15 @ 8:00 pm ET and Nov 17 @ 3:00 pm ET"
               )
    end

    test "parses dates with ª separator (Exit Points example)" do
      assert %DateParser{
               date: ~D[2025-08-29],
               additional_dates: [
                 ~D[2025-09-26],
                 ~D[2025-10-31],
                 ~D[2025-11-28],
                 ~D[2026-01-30],
                 ~D[2026-02-27],
                 ~D[2026-03-27],
                 ~D[2026-04-24],
                 ~D[2026-05-29],
                 ~D[2026-06-26]
               ]
             } ==
               DateParser.parse_dates(
                 "Exit Points 25|26",
                 "Aug 29 • Sep 26 • Oct 31 • Nov 28 ª Jan 30 • Feb 27 • Mar 27 • Apr 24 • May 29 • Jun 26 @ 7:30 pm ET"
               )
    end

    test "parses dates with multiple ª separators" do
      assert %DateParser{
               date: ~D[2024-11-28],
               additional_dates: [
                 ~D[2025-01-30],
                 ~D[2025-02-27]
               ]
             } ==
               DateParser.parse_dates(
                 "Test Event 24|25",
                 "Nov 28 ª Jan 30 ª Feb 27 @ 7:30 pm ET"
               )
    end
  end
end
