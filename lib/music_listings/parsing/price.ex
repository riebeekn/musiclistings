defmodule MusicListings.Parsing.Price do
  @moduledoc """
  Struct and functions to represent / parse an event prices
  """
  @type t :: %__MODULE__{
          format: :fixed | :free | :pwyc | :range | :unknown | :variable,
          lo: Decimal.t() | nil,
          hi: Decimal.t() | nil
        }
  defstruct [:format, :lo, :hi]

  def unknown, do: %__MODULE__{format: :unknown, lo: nil, hi: nil}

  def new(nil), do: unknown()

  def new(""), do: unknown()

  def new(price_string) do
    price_string = clean_price_string(price_string)

    cond do
      price_string == "" ->
        unknown()

      String.contains?(price_string, "free") ->
        %__MODULE__{format: :free, lo: nil, hi: nil}

      String.contains?(price_string, "pwyc") ->
        %__MODULE__{format: :pwyc, lo: nil, hi: nil}

      true ->
        parse_amounts(price_string)
    end
  end

  # Prices are written as a single amount ("20"), a range ("15-30") or, when a
  # promoter lists every tier, a list ("$10, $15, $20").
  defp parse_amounts(price_string) do
    variable_price? =
      String.contains?(price_string, "+") || String.contains?(price_string, "from")

    price_string
    |> String.replace("+", "")
    |> String.replace("from", "")
    |> String.split(["-", ","])
    |> Enum.map(&to_decimal/1)
    |> Enum.reject(&is_nil/1)
    |> case do
      [] ->
        unknown()

      amounts ->
        lo = Enum.min(amounts, Decimal)
        hi = Enum.max(amounts, Decimal)

        %__MODULE__{lo: lo, hi: hi, format: price_format(lo, hi, variable_price?)}
    end
  end

  defp to_decimal(string) do
    case string |> String.trim() |> String.replace("$", "") |> Decimal.parse() do
      {decimal, _rest} -> decimal
      :error -> nil
    end
  end

  defp clean_price_string(price_string) do
    price_string
    |> String.downcase()
    |> String.replace("(plus service fees)", "")
    |> String.replace("(plus fees)", "")
    |> String.replace("price:", "")
    |> String.replace("advance", "")
    |> String.replace("$", "")
    |> String.replace("door", "")
    |> String.replace("cad", "")
    |> String.trim()
  end

  defp price_format(_lo, _hi, true), do: :variable

  defp price_format(lo, hi, _variable_price?) do
    if Decimal.equal?(lo, hi), do: :fixed, else: :range
  end
end
