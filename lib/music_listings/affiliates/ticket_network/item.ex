defmodule MusicListings.Affiliates.TicketNetwork.Item do
  @moduledoc """
  A single TicketNetwork product, decoded from an Impact.com catalog row.

  Impact's catalog schema is generic (it is built for retail products), and
  TicketNetwork repurposes its fields.  The mapping is not obvious from the
  field names, so it is recorded here:

    | Impact field   | Actually holds                          |
    |----------------|-----------------------------------------|
    | `Name`         | event / artist name                     |
    | `Labels`       | venue name (single element)             |
    | `Manufacturer` | venue street address                    |
    | `Size`         | venue postal code                       |
    | `Gtin`         | city (what we filter the catalog on)    |
    | `Mpn` / `Asin` | province / country                      |
    | `LaunchDate`   | event date, offset by a day - see below |
    | `Text1`        | price range, and the stock signal       |
    | `Url`          | the affiliate link                      |

  Three quirks matter:

    * `LaunchDate` runs a day behind the real event date, and its *time*
      component is a placeholder (only ever 19:00 or 20:00, disagreeing with
      the venue's real start time more often than not).  We therefore keep only
      the date, exactly as supplied, and leave the day-shift to
      `MusicListings.Affiliates.TicketNetwork.Matcher`, which resolves it by
      requiring a title match rather than assuming a fixed offset.

    * A handful of rows carry nonsense years (2074, 2075, 2076 in the catalog
      as sampled).  They are dropped here.

    * `Text1` is useless as *price* data but is the catalog's only stock signal.
  """
  alias MusicListings.Affiliates.TicketNetwork.VenueMap

  @type t :: %__MODULE__{
          catalog_item_id: String.t(),
          name: String.t(),
          venue_label: String.t(),
          date: Date.t(),
          url: String.t()
        }

  defstruct [:catalog_item_id, :name, :venue_label, :date, :url]

  # Anything further out than this is junk data rather than a real on-sale.
  @max_years_ahead 3

  @doc """
  Builds an item from a decoded catalog row, or returns `nil` when the row is
  unusable (missing a name, venue, url or a sane date) or has no tickets left to
  sell (see the `Text1` note above).
  """
  @spec new(map(), today :: Date.t()) :: t() | nil
  def new(row, today) do
    with {:ok, name} <- fetch_string(row, "Name"),
         {:ok, url} <- fetch_string(row, "Url"),
         {:ok, venue_label} <- fetch_venue_label(row),
         {:ok, date} <- fetch_date(row, today),
         :ok <- check_in_stock(row) do
      %__MODULE__{
        catalog_item_id: row["CatalogItemId"],
        name: name,
        venue_label: venue_label,
        date: date,
        url: url
      }
    else
      :error -> nil
    end
  end

  @doc """
  The parser module name of the venue this item belongs to, or `nil` when
  TicketNetwork covers a venue we don't track.
  """
  @spec parser_module_name(t()) :: String.t() | nil
  def parser_module_name(%__MODULE__{venue_label: venue_label}) do
    VenueMap.parser_module_name(venue_label)
  end

  defp fetch_string(row, key) do
    case row[key] do
      value when is_binary(value) ->
        case String.trim(value) do
          "" -> :error
          trimmed -> {:ok, trimmed}
        end

      _other ->
        :error
    end
  end

  defp fetch_venue_label(row) do
    case row["Labels"] do
      [label | _rest] when is_binary(label) -> fetch_string(%{"Labels" => label}, "Labels")
      _other -> :error
    end
  end

  # The catalog's stock signal: a row whose price range is all zeroes has no
  # listings behind it.  Reads every amount in the range rather than matching the
  # exact `$0.00- $0.00` string, so a change in spacing or a one-sided range
  # doesn't silently start letting dead rows through.
  defp check_in_stock(row) do
    with {:ok, text} <- fetch_string(row, "Text1"),
         true <- text |> parse_amounts() |> Enum.any?(&(&1 > 0)) do
      :ok
    else
      _other -> :error
    end
  end

  defp parse_amounts(text) do
    ~r/\$\s*(\d+(?:\.\d+)?)/
    |> Regex.scan(text)
    |> Enum.flat_map(fn [_full, amount] ->
      case Float.parse(amount) do
        {value, _rest} -> [value]
        :error -> []
      end
    end)
  end

  # Takes the date exactly as written, rather than parsing the full timestamp.
  #
  # This is deliberate: `DateTime.from_iso8601/1` normalises to UTC, and since
  # every TicketNetwork timestamp is a 19:00 or 20:00 Eastern placeholder, that
  # conversion rolls each one past midnight and silently shifts the date a day
  # forward.  It would happen to cancel out the offset the matcher is correcting
  # for, leaving two bugs that hide each other and would come apart the moment
  # TicketNetwork changed either the placeholder time or the offset.
  defp fetch_date(row, today) do
    with {:ok, raw} <- fetch_string(row, "LaunchDate"),
         {:ok, date} <- raw |> String.slice(0, 10) |> Date.from_iso8601(),
         true <- Date.diff(date, today) <= @max_years_ahead * 365 do
      {:ok, date}
    else
      _other -> :error
    end
  end
end
