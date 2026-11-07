defmodule MusicListings.Parsing.VenueParsers.ArraymusicParser.DateParserTest do
  use ExUnit.Case, async: true

  alias MusicListings.Parsing.VenueParsers.ArraymusicParser.DateParser

  describe "parse_dates/2" do
    test "parses single date format" do
      assert %DateParser{date: ~D[2025-02-15], additional_dates: []} ==
               DateParser.parse_dates("February 15, 2025 @ 8:00 pm ET", 2024)
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
                 "Sep 26 • Oct 31 • Nov 28 • Jan 30 • Feb 27 • Mar 27 • Apr 24 • May 29 • Jun 26 @ 7:30 pm ET",
                 2024
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
                 "Jan 20, 2025 • Feb 17 • Mar 17 • Apr 27 • May 19 • June 16 @ 7:00 pm ET",
                 2024
               )
    end

    test "places a single date without a year in the season" do
      assert %DateParser{date: ~D[2024-11-01], additional_dates: []} ==
               DateParser.parse_dates("Nov 1 @ 8:00 pm ET", 2024)
    end

    test "parses 2 dates without a year joined by and" do
      assert %DateParser{date: ~D[2024-11-15], additional_dates: [~D[2024-11-17]]} ==
               DateParser.parse_dates("Nov 15 @ 8:00 pm ET and Nov 17 @ 3:00 pm ET", 2024)
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
                 "Aug 29 • Sep 26 • Oct 31 • Nov 28 ª Jan 30 • Feb 27 • Mar 27 • Apr 24 • May 29 • Jun 26 @ 7:30 pm ET",
                 2025
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
                 "Nov 28 ª Jan 30 ª Feb 27 @ 7:30 pm ET",
                 2024
               )
    end
  end

  describe "parse_dates/2 with the 26|27 formats" do
    test "parses a single date" do
      assert %DateParser{date: ~D[2026-11-21], additional_dates: []} ==
               DateParser.parse_dates("Nov. 21, 2026 @ 7:30 pm ET", 2026)
    end

    test "parses two days joined by an ampersand" do
      assert %DateParser{date: ~D[2026-12-18], additional_dates: [~D[2026-12-19]]} ==
               DateParser.parse_dates("December 18 & 19, 2026", 2026)
    end

    test "parses a range of days" do
      assert %DateParser{date: ~D[2027-04-23], additional_dates: [~D[2027-04-24], ~D[2027-04-25]]} ==
               DateParser.parse_dates("April 23 – 25, 2027", 2026)
    end

    test "places dates without a year in the season and skips a month missing its day" do
      assert %DateParser{date: ~D[2026-09-27], additional_dates: [~D[2026-10-25], ~D[2027-01-31]]} ==
               DateParser.parse_dates("Sep 27 •\u00A0Oct 25 •\u00A0Nov •\u00A0Jan 31", 2026)
    end

    test "returns no date when nothing parses" do
      assert %DateParser{date: nil, additional_dates: []} == DateParser.parse_dates("TBA", 2026)
    end
  end

  describe "parse_time/1" do
    test "parses the time" do
      assert ~T[20:00:00] == DateParser.parse_time("Sep 11 • Oct 9 @ 8:00 pm ET")

      assert ~T[12:00:00] ==
               DateParser.parse_time("December 12, 2026 @ 12:00 noon – 12:00 midnight ET")

      assert nil == DateParser.parse_time("December 18 & 19, 2026")
    end
  end
end
