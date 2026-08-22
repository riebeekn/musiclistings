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

  describe "build_date_from_month_day_strings_anchored/3" do
    test "keeps the anchor's year when the date follows it" do
      assert {:ok, ~D[2025-08-24]} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "Aug",
                 "24",
                 ~D[2025-08-10]
               )
    end

    test "rolls into the next year when the date precedes the anchor" do
      assert {:ok, ~D[2026-01-15]} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "January",
                 "15",
                 ~D[2025-12-28]
               )
    end

    test "leaves a date that has already passed in the past" do
      # The whole point: a listing published long ago for a show that has since
      # happened must not be pushed a year forward, no matter when we parse it
      assert {:ok, ~D[2025-06-05]} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "Jun",
                 "05",
                 ~D[2025-05-22]
               )
    end

    test "allows two days of grace before the anchor" do
      assert {:ok, ~D[2025-08-08]} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "Aug",
                 "08",
                 ~D[2025-08-10]
               )

      assert {:ok, ~D[2026-08-07]} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "Aug",
                 "07",
                 ~D[2025-08-10]
               )
    end

    test "returns an error when the rolled over date does not exist" do
      assert {:error, :invalid_date} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "Feb",
                 "29",
                 ~D[2024-06-01]
               )
    end

    test "returns an error for an unparseable month or day" do
      assert {:error, :invalid_date} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "NOTAMONTH",
                 "1st",
                 ~D[2025-08-10]
               )

      assert {:error, :invalid_date} ==
               ParseHelpers.build_date_from_month_day_strings_anchored(
                 "Feb",
                 "31",
                 ~D[2025-01-01]
               )
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

  describe "fix_encoding/1" do
    test "decodes named entities" do
      assert "Dayfields (and the GALs)" ==
               ParseHelpers.fix_encoding("Dayfields&nbsp;(and the GALs)")

      assert "Rima & The Bees" == ParseHelpers.fix_encoding("Rima &amp; The Bees")
      assert "Café du Nord" == ParseHelpers.fix_encoding("Caf&eacute; du Nord")
    end

    test "decodes decimal and hexadecimal entities" do
      assert "Beyoncé" == ParseHelpers.fix_encoding("Beyonc&#233;")
      assert "Sold 'Out'" == ParseHelpers.fix_encoding("Sold &#x27;Out&#x27;")
    end

    test "folds smart punctuation to its ascii equivalent" do
      assert "Bob Marley's Legend" == ParseHelpers.fix_encoding("Bob Marley&#8217;s Legend")

      assert "Elevation - The U2 Show" ==
               ParseHelpers.fix_encoding("Elevation &#8211; The U2 Show")

      assert "Awake & Dreaming" == ParseHelpers.fix_encoding("Awake &#038; Dreaming")
    end

    test "normalizes invisible code points to a space" do
      assert "zero width" == ParseHelpers.fix_encoding("zero&#8203;width")
      assert "no break" == ParseHelpers.fix_encoding("no&#160;break")
    end

    test "decodes entities that are themselves encoded" do
      assert "A & B" == ParseHelpers.fix_encoding("A &amp;amp; B")
    end

    test "decodes unicode escapes" do
      assert "école" == ParseHelpers.fix_encoding("\\u00e9cole")
    end

    test "leaves a bare ampersand and unknown entities alone" do
      assert "Blues & Burlesque" == ParseHelpers.fix_encoding("Blues & Burlesque")
      assert "Bare &notanentity; stays" == ParseHelpers.fix_encoding("Bare &notanentity; stays")
    end
  end

  describe "sanitize_ticket_url/1" do
    test "returns nil for nil" do
      assert nil == ParseHelpers.sanitize_ticket_url(nil)
    end

    test "leaves a url with no query params alone" do
      url = "https://www.ticketmaster.ca/event/10006481D41C232F"

      assert url == ParseHelpers.sanitize_ticket_url(url)
    end

    test "strips google analytics cross domain linker params" do
      url =
        "https://www.ticketmaster.ca/interpol-toronto-ontario-10-02-2026/event/1000649B81805BD2?_gl=1*18g11vq*_gcl_au*MTMxOTQ5MzE3Ni4xNzgzNzgzNzgz*_ga*NjE1OTM5NzY1LjE3ODM3ODM3ODM.*_ga_J0R9TBXM89*czE3ODM3ODM3ODMkbzEkZzEkdDE3ODM3ODM4MTIkajMxJGwwJGgw"

      assert "https://www.ticketmaster.ca/interpol-toronto-ontario-10-02-2026/event/1000649B81805BD2" ==
               ParseHelpers.sanitize_ticket_url(url)
    end

    test "strips utm and click id params" do
      url = "https://www.ticketweb.ca/event/some-show?utm_source=venue&gclid=abc123&fbclid=xyz"

      assert "https://www.ticketweb.ca/event/some-show" == ParseHelpers.sanitize_ticket_url(url)
    end

    test "keeps params the ticket vendor needs" do
      url = "https://www.ticketweb.ca/event/some-show?pl=Rebel&utm_medium=web"

      assert "https://www.ticketweb.ca/event/some-show?pl=Rebel" ==
               ParseHelpers.sanitize_ticket_url(url)
    end
  end
end
