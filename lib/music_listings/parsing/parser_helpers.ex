defmodule MusicListings.Parsing.ParseHelpers do
  @moduledoc """
  Module that contains helper / common functions around parsing
  """

  alias MusicListingsUtilities.DateHelpers

  # ===========================================================================
  # General helpers
  # ===========================================================================
  @doc """
  Bit of a hack to facilitate pulling data locally... Req converts it
  to a map when pulling from www, where-as locally we just have a file
  so when pulling local we get a string and need to decode it
  """
  @spec maybe_decode!(String.t() | map()) :: term()
  def maybe_decode!(content) do
    if is_binary(content) do
      Jason.decode!(content)
    else
      content
    end
  end

  @spec strip_extra_quotes(String.t()) :: String.t()
  def strip_extra_quotes(json_string) do
    # Regular expression to find extraneous quotes
    regex = ~r/":\s*"[^"]*",\s*"/

    cleaned_json =
      Regex.replace(regex, json_string, fn match ->
        String.replace(match, ",\"", ",")
      end)

    cleaned_json
    |> String.replace(~r/,\s*([}\]])/, "\\1")
    |> String.replace(~r/""+/, "\"")
    |> String.replace(~r/,\s*"/, ", \"")
  end

  @spec replace_punctuation_and_spaces(String.t()) :: String.t()
  def replace_punctuation_and_spaces(string) do
    space_and_punct_regex = ~r/[\p{P}\p{Z}|]+/u

    Regex.replace(space_and_punct_regex, string, "_")
  end

  @spec clean_html(String.t()) :: String.t()
  def clean_html(content) do
    content
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.replace("\\\\", "\\")
    |> String.replace("\\\"", "\"")
    |> String.replace("\\n", "\n")
    |> String.replace("\\t", "\t")
    |> String.replace("\\/", "/")
  end

  # Entities we deliberately fold to an ASCII equivalent rather than decode
  # faithfully, so titles sort, search and compare cleanly.  These run before
  # the generic decoder below, which would otherwise yield the real code point
  # (ie. &#8217; would become a curly apostrophe instead of a straight one).
  @ascii_entities %{
    "#8217" => "'",
    "rsquo" => "'",
    "#8216" => "'",
    "lsquo" => "'",
    "#8220" => "\"",
    "ldquo" => "\"",
    "#8221" => "\"",
    "rdquo" => "\"",
    "#8211" => "-",
    "ndash" => "-",
    "#8212" => "-",
    "mdash" => "-",
    "#8230" => "...",
    "hellip" => "...",
    "#038" => "&",
    "amp" => "&"
  }

  # Named entities the numeric decoder can't handle on its own.  Unlike the
  # table above these decode faithfully - an accent carries meaning, so
  # "Caf&eacute;" should read "Café" rather than "Cafe".
  @named_entities %{
    "nbsp" => " ",
    "lt" => "<",
    "gt" => ">",
    "quot" => "\"",
    "apos" => "'",
    "bull" => "•",
    "copy" => "©",
    "reg" => "®",
    "middot" => "·",
    "raquo" => "»",
    "laquo" => "«",
    "rarr" => "→",
    "times" => "×",
    "semi" => ";",
    "deg" => "°",
    "agrave" => "à",
    "aacute" => "á",
    "auml" => "ä",
    "ccedil" => "ç",
    "egrave" => "è",
    "eacute" => "é",
    "ecirc" => "ê",
    "iacute" => "í",
    "ntilde" => "ñ",
    "oacute" => "ó",
    "ouml" => "ö",
    "uacute" => "ú",
    "uuml" => "ü"
  }

  # Code points that are technically whitespace but read as noise in a title:
  # non breaking space, zero width space and byte order mark.
  @invisible_code_points [0xA0, 0x200B, 0xFEFF]

  @spec fix_encoding(String.t()) :: String.t()
  def fix_encoding(content) do
    content
    |> decode_unicode_escapes()
    |> decode_html_entities()
  end

  # Venue feeds arrive with entities encoded to varying depths - a title can
  # carry a bare &nbsp;, a numeric &#160;, or an &amp;nbsp; that only becomes an
  # entity once the outer &amp; is decoded.  Decoding repeatedly settles all
  # three, and stopping as soon as a pass changes nothing keeps a title that
  # legitimately contains "&" from looping.
  defp decode_html_entities(content) do
    case decode_entities_once(content) do
      ^content -> content
      decoded -> decode_html_entities(decoded)
    end
  end

  defp decode_entities_once(content) do
    Regex.replace(
      ~r/&(#[xX]?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);/,
      content,
      fn match, entity -> decode_entity(entity) || match end
    )
  end

  defp decode_entity(entity) do
    Map.get(@ascii_entities, entity) || Map.get(@named_entities, entity) ||
      decode_numeric_entity(entity)
  end

  defp decode_numeric_entity("#x" <> hex), do: hex |> parse_int(16) |> to_code_point()
  defp decode_numeric_entity("#X" <> hex), do: hex |> parse_int(16) |> to_code_point()
  defp decode_numeric_entity("#" <> digits), do: digits |> parse_int(10) |> to_code_point()
  defp decode_numeric_entity(_named), do: nil

  defp parse_int(string, base) do
    case Integer.parse(string, base) do
      {integer, ""} -> integer
      _not_a_number -> nil
    end
  end

  defp to_code_point(nil), do: nil
  defp to_code_point(code_point) when code_point in @invisible_code_points, do: " "

  defp to_code_point(code_point) do
    if code_point in 0..0x10FFFF, do: List.to_string([code_point])
  end

  defp decode_unicode_escapes(content) do
    Regex.replace(~r/\\u([0-9a-fA-F]{4})/, content, fn _match, hex ->
      hex
      |> String.to_integer(16)
      |> List.wrap()
      |> List.to_string()
    end)
  end

  # ===========================================================================
  # Id helpers
  # ===========================================================================
  @spec build_id_from_title_and_date(title :: String.t(), date :: Date.t()) :: String.t()
  def build_id_from_title_and_date(title, date) do
    "#{title}_#{date}"
    |> replace_punctuation_and_spaces()
    |> String.downcase()
    |> String.replace("cancelled_", "")
    |> String.replace("rescheduled_", "")
    |> String.replace("postponed_", "")
  end

  def build_id_from_venue_and_date(venue_name, date) do
    "#{venue_name}_#{date}"
    |> replace_punctuation_and_spaces()
  end

  def build_id_from_venue_and_datetime(venue_name, date, time) do
    "#{venue_name}_#{date}_#{time}"
    |> replace_punctuation_and_spaces()
  end

  # ===========================================================================
  # Age restriction helpers
  # ===========================================================================
  @spec age_restriction_string_to_enum(nil | String.t()) ::
          :all_ages | :eighteen_plus | :nineteen_plus
  @all_ages_strings ["all", "all ages", "all ages event", "this is an all ages event"]
  @eighteen_plus_strings ["18+", "this is an 18+ event"]
  @nineteen_plus_strings ["19+", "19+ event", "this is an 19+ event"]

  def age_restriction_string_to_enum(age_restriction_string) do
    normalized =
      (age_restriction_string || "")
      |> String.trim()
      |> String.downcase()

    cond do
      normalized in @all_ages_strings -> :all_ages
      normalized in @eighteen_plus_strings -> :eighteen_plus
      normalized in @nineteen_plus_strings -> :nineteen_plus
      true -> :unknown
    end
  end

  # ===========================================================================
  # Date helpers
  # ===========================================================================
  @spec build_date_from_year_month_day_strings(
          year_string :: String.t(),
          month_string :: String.t(),
          day_string :: String.t()
        ) :: {:ok, Date.t()} | {:error, :invalid_date}
  def build_date_from_year_month_day_strings(year_string, month_string, day_string) do
    with {:ok, day} <- day_string_to_integer(day_string),
         {:ok, month} <- month_string |> clean_month_string() |> month_string_to_integer(),
         {:ok, year} <- year_string_to_integer(year_string),
         {:ok, date} <- Date.new(year, month, day) do
      {:ok, date}
    else
      _error -> {:error, :invalid_date}
    end
  end

  @doc """
  Not all sites include the year in the event date, in those cases use this
  function which pseudo intelligently determines the year.

  Prefer `build_date_from_month_day_strings_anchored/3` when the source offers
  a date that reliably precedes the event, such as a CMS publish date - the
  year it yields doesn't depend on when the crawl happens to run.
  """
  @spec build_date_from_month_day_strings(
          month_string :: String.t(),
          day_string :: String.t()
        ) :: {:ok, Date.t()} | {:error, :invalid_date}
  def build_date_from_month_day_strings(month_string, day_string) do
    today = DateHelpers.today()

    with {:ok, day} <- day_string_to_integer(day_string),
         {:ok, month} <- month_string |> clean_month_string() |> month_string_to_integer(),
         {:ok, candidate_date} <- Date.new(today.year, month, day),
         {:ok, date} <- maybe_adjust_year(candidate_date, today) do
      {:ok, date}
    else
      _error -> {:error, :invalid_date}
    end
  end

  @doc """
  Builds a date from a month / day that carries no year, using `anchor_date` -
  a date known to precede the event, such as the CMS publish date of the
  listing - to resolve the year.

  Picks the earliest year for which the resulting date is not before the
  anchor, so a listing published in December for a January show rolls into the
  following year, while a stale listing for a show that has already happened
  stays in the past rather than being bumped a year forward.

  Prefer this over `build_date_from_month_day_strings/2` whenever the source
  provides a trustworthy anchor: the result does not depend on when the crawl
  happens to run.
  """
  @spec build_date_from_month_day_strings_anchored(
          month_string :: String.t(),
          day_string :: String.t(),
          anchor_date :: Date.t()
        ) :: {:ok, Date.t()} | {:error, :invalid_date}
  def build_date_from_month_day_strings_anchored(month_string, day_string, anchor_date) do
    with {:ok, day} <- day_string_to_integer(day_string),
         {:ok, month} <- month_string |> clean_month_string() |> month_string_to_integer(),
         {:ok, candidate_date} <- Date.new(anchor_date.year, month, day),
         {:ok, date} <- maybe_increment_year_to_clear_anchor(candidate_date, anchor_date) do
      {:ok, date}
    else
      _error -> {:error, :invalid_date}
    end
  end

  defp maybe_increment_year_to_clear_anchor(candidate_date, anchor_date) do
    # A couple of days of grace covers timezone skew and listings published the
    # day of the show - it matches the tolerance the crawler itself applies
    # when rejecting past events.
    earliest_date = Date.add(anchor_date, -2)

    if Date.before?(candidate_date, earliest_date) do
      # Date.new/3 rather than Date.new!/3: a Feb 29 candidate rolling into a
      # non leap year has no valid date, and we'd rather report that than raise
      Date.new(candidate_date.year + 1, candidate_date.month, candidate_date.day)
    else
      {:ok, candidate_date}
    end
  end

  @doc """
  Parses a date string in "Day, Month DD" format (e.g., "Friday, January 23")
  and returns a Date. The year is determined by build_date_from_month_day_strings.
  """
  @spec parse_day_month_day_string(String.t()) :: {:ok, Date.t()} | {:error, :invalid_date}
  def parse_day_month_day_string(date_string) do
    with [_day_of_week, month_day] <- date_string |> String.trim() |> String.split(", "),
         [month_string, day_string] <- String.split(month_day) do
      build_date_from_month_day_strings(month_string, day_string)
    else
      _error -> {:error, :invalid_date}
    end
  end

  # With no year to go on, the event is assumed to fall inside a window that
  # starts however long a site might keep a show listed after it happens.  The
  # window is exactly one year wide, so every month/day maps to a single date
  # and a candidate past the far edge belongs to the year behind.
  #
  # The far edge matters as much as the near one: on New Year's Day a lingering
  # "Dec. 26" would otherwise be read as the December still to come - a whole
  # year late.  Pulling it back instead puts it in the past, where the crawler
  # drops it.
  @stale_listing_tolerance_days 35
  @booking_horizon_days 365 - @stale_listing_tolerance_days

  defp maybe_adjust_year(candidate_date, today) do
    cond do
      Date.before?(candidate_date, Date.add(today, -@stale_listing_tolerance_days)) ->
        shift_year(candidate_date, 1)

      Date.after?(candidate_date, Date.add(today, @booking_horizon_days)) ->
        shift_year(candidate_date, -1)

      true ->
        {:ok, candidate_date}
    end
  end

  # Date.new/3 rather than Date.new!/3: Feb 29 has no counterpart in a
  # neighbouring non leap year, and that's an unparseable date, not a crash
  defp shift_year(date, offset) do
    Date.new(date.year + offset, date.month, date.day)
  end

  defp clean_month_string(month_string) do
    month_string
    |> String.downcase()
    |> String.replace(".", "")
    |> String.trim()
  end

  defp month_string_to_integer("january"), do: {:ok, 1}
  defp month_string_to_integer("jan"), do: {:ok, 1}
  defp month_string_to_integer("01"), do: {:ok, 1}
  defp month_string_to_integer("february"), do: {:ok, 2}
  defp month_string_to_integer("feb"), do: {:ok, 2}
  defp month_string_to_integer("02"), do: {:ok, 2}
  defp month_string_to_integer("march"), do: {:ok, 3}
  defp month_string_to_integer("mar"), do: {:ok, 3}
  defp month_string_to_integer("03"), do: {:ok, 3}
  defp month_string_to_integer("april"), do: {:ok, 4}
  defp month_string_to_integer("apr"), do: {:ok, 4}
  defp month_string_to_integer("04"), do: {:ok, 4}
  defp month_string_to_integer("may"), do: {:ok, 5}
  defp month_string_to_integer("05"), do: {:ok, 5}
  defp month_string_to_integer("june"), do: {:ok, 6}
  defp month_string_to_integer("jun"), do: {:ok, 6}
  defp month_string_to_integer("06"), do: {:ok, 6}
  defp month_string_to_integer("july"), do: {:ok, 7}
  defp month_string_to_integer("jul"), do: {:ok, 7}
  defp month_string_to_integer("07"), do: {:ok, 7}
  defp month_string_to_integer("august"), do: {:ok, 8}
  defp month_string_to_integer("aug"), do: {:ok, 8}
  defp month_string_to_integer("08"), do: {:ok, 8}
  defp month_string_to_integer("september"), do: {:ok, 9}
  defp month_string_to_integer("sep"), do: {:ok, 9}
  defp month_string_to_integer("sept"), do: {:ok, 9}
  defp month_string_to_integer("09"), do: {:ok, 9}
  defp month_string_to_integer("october"), do: {:ok, 10}
  defp month_string_to_integer("oct"), do: {:ok, 10}
  defp month_string_to_integer("10"), do: {:ok, 10}
  defp month_string_to_integer("november"), do: {:ok, 11}
  defp month_string_to_integer("nov"), do: {:ok, 11}
  defp month_string_to_integer("11"), do: {:ok, 11}
  defp month_string_to_integer("december"), do: {:ok, 12}
  defp month_string_to_integer("dec"), do: {:ok, 12}
  defp month_string_to_integer("12"), do: {:ok, 12}
  defp month_string_to_integer(_month_string), do: {:error, :invalid_month}

  defp day_string_to_integer(day_string) do
    result =
      day_string
      |> String.replace(",", "")
      |> String.replace(".", "")
      |> String.replace("st", "")
      |> String.replace("nd", "")
      |> String.replace("rd", "")
      |> String.replace("th", "")
      |> String.replace("o", "")
      |> String.trim()
      |> Integer.parse()

    case result do
      {day, _remainder} -> {:ok, day}
      :error -> {:error, :invalid_day}
    end
  end

  defp year_string_to_integer(year_string) do
    result =
      year_string
      |> String.replace(",", "")
      |> String.trim()
      |> Integer.parse()

    case result do
      {year, _remainder} -> {:ok, year}
      :error -> {:error, :invalid_year}
    end
  end

  # ===========================================================================
  # Time helpers
  # ===========================================================================
  @spec build_time_from_time_string(String.t() | nil) :: {:ok, Time.t()} | {:error, :invalid_time}
  def build_time_from_time_string(nil), do: {:error, :invalid_time}

  def build_time_from_time_string(time_string) do
    result =
      time_string
      |> String.replace("EST", "")
      |> String.replace("EDT", "")
      |> String.replace(":PM", " pm")
      |> String.replace("p.m.", "pm")
      |> String.trim()
      |> String.downcase()
      |> String.split(":")
      |> case do
        [hour_string, minute_string] ->
          with {hour, _remainder} <- Integer.parse(hour_string),
               minute_cleaned =
                 minute_string
                 |> String.replace("pm", "")
                 |> String.replace("am", "")
                 |> String.trim(),
               {minute, _remainder} <- Integer.parse(minute_cleaned) do
            hour = maybe_adjust_for_pm(hour, minute_string)
            Time.new(hour, minute, 0)
          else
            _error -> {:error, :invalid_time}
          end

        [hour_string] ->
          hour_string
          |> String.replace("pm", "")
          |> String.replace("am", "")
          |> String.trim()
          |> Integer.parse()
          |> case do
            {hour, _remainder} ->
              hour = maybe_adjust_for_pm(hour, hour_string)
              Time.new(hour, 0, 0)

            :error ->
              {:error, :invalid_time}
          end

        _other ->
          {:error, :invalid_time}
      end

    case result do
      {:ok, time} -> {:ok, time}
      _error -> {:error, :invalid_time}
    end
  end

  @doc """
  As `build_time_from_time_string/1`, for the common case of a caller that has
  nothing to say about an unparseable time and just wants `nil`.
  """
  @spec time_from_time_string(String.t() | nil) :: Time.t() | nil
  def time_from_time_string(time_string) do
    case build_time_from_time_string(time_string) do
      {:ok, time} -> time
      {:error, :invalid_time} -> nil
    end
  end

  @doc """
  For handling datetime strings missing seconds and offset
  i.e convert a dt string of the format 2024-08-31T19:00
  to 2024-08-31T19:00:00-04:00
  """
  @spec add_seconds_and_offset_to_datetime_string(String.t()) :: String.t()
  def add_seconds_and_offset_to_datetime_string(dt_string), do: "#{dt_string}:00-04:00"

  @doc """
  For handling datetime strings missing seconds
  i.e. convert a dt string of the format 2024-08-31T19:00-04:00
  to 2024-08-31T19:00:00-04:00
  """
  @spec add_seconds_to_datetime_string(String.t()) :: String.t()
  def add_seconds_to_datetime_string(dt_string) do
    [date, time_with_offset] = String.split(dt_string, "T")
    [time, offset] = String.split(time_with_offset, "-")
    time_with_seconds = "#{time}:00"
    "#{date}T#{time_with_seconds}-#{offset}"
  end

  defp maybe_adjust_for_pm(hour, minute_string) do
    if String.contains?(minute_string, "pm") do
      if hour == 12 do
        12
      else
        hour + 12
      end
    else
      hour
    end
  end

  # ===========================================================================
  # Ticket url helpers
  # ===========================================================================
  @tracking_params ~w(gclid fbclid msclkid mc_cid mc_eid)
  @tracking_param_prefixes ~w(_ga _gl utm_)

  @doc """
  Strips analytics tracking params (ie. the `_gl` / `_ga` params a Google
  Analytics cross domain linker appends) from a ticket url, leaving any params
  the ticket vendor actually needs.

  We store the cleaned url so the outbound link we build from it - including
  the affiliate redirect it gets wrapped in - carries only meaningful params.
  """
  @spec sanitize_ticket_url(String.t() | nil) :: String.t() | nil
  def sanitize_ticket_url(nil), do: nil

  def sanitize_ticket_url(url) do
    uri = URI.parse(url)

    %{uri | query: sanitized_query(uri.query)}
    |> URI.to_string()
  end

  defp sanitized_query(nil), do: nil

  defp sanitized_query(query) do
    query
    |> URI.decode_query()
    |> Enum.reject(fn {param, _value} -> tracking_param?(param) end)
    |> case do
      [] -> nil
      params -> params |> Enum.sort() |> URI.encode_query()
    end
  end

  defp tracking_param?(param) do
    normalized = String.downcase(param)

    normalized in @tracking_params or
      Enum.any?(@tracking_param_prefixes, &String.starts_with?(normalized, &1))
  end
end
