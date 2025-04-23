defmodule MusicListings.Events.EventInfo do
  @moduledoc """
  Struct to represent an event
  """
  alias MusicListings.Events.ShowTimeInfo
  alias MusicListingsSchema.Venue

  @type t :: %__MODULE__{
          date: Date.t(),
          title: String.t(),
          openers: [String.t()],
          venue: Venue.t(),
          age_restriction: :all_ages | :eighteen_plus | :nineteen_plus | :unknown,
          price_format: :fixed | :free | :pwyc | :range | :unknown | :variable,
          price_lo: Decimal.t(),
          price_hi: Decimal.t(),
          showtimes: list(ShowTimeInfo.t()),
          has_multiple_showtimes?: boolean()
        }

  defstruct [
    :date,
    :title,
    :openers,
    :venue,
    :age_restriction,
    :price_format,
    :price_lo,
    :price_hi,
    :showtimes,
    :has_multiple_showtimes?
  ]
end
