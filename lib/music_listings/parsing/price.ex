defmodule MusicListings.Parsing.Price do
  @moduledoc """
  Struct and functions to represent / parse an event prices
  """
  @type t :: %__MODULE__{
          format: :fixed | :range | :unknown | :variable,
          lo: Decimal.t() | nil,
          hi: Decimal.t() | nil
        }
  defstruct [:format, :lo, :hi]

  def unknown, do: %__MODULE__{format: :unknown, lo: nil, hi: nil}

  def new(nil), do: unknown()

  def new(price_string) do
    price_string = clean_price_string(price_string)

    variable_price? = String.contains?(price_string, "+")

    [lo_string, hi_string] =
      price_string
      |> String.replace("+", "")
      |> String.split("-")
      |> case do
        [lo, hi] -> [lo, hi]
        [single_price] -> [single_price, single_price]
      end

    %__MODULE__{
      lo: lo_string |> String.trim() |> String.replace("$", "") |> Decimal.new(),
      hi: hi_string |> String.trim() |> String.replace("$", "") |> Decimal.new(),
      format: price_format(lo_string, hi_string, variable_price?)
    }
  end

  defp clean_price_string(price_string) do
    price_string
    |> String.downcase()
    |> String.replace("(plus service fees)", "")
    |> String.replace("(plus fees)", "")
    |> String.replace("price:", "")
    |> String.replace("advance", "")
    |> String.replace("$", "")
    |> String.trim()
  end

  defp price_format(_lo, _hi, true), do: :variable
  defp price_format(lo, hi, _variable_price?) when lo == hi, do: :fixed
  defp price_format(_lo, _hi, _variable_price?), do: :range
end
