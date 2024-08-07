defmodule MusicListings.Events.PagedEvents do
  @moduledoc """
  Struct to represent the result of an events query
  """
  alias MusicListingsSchema.Event

  @type t :: %__MODULE__{
          current_page: pos_integer(),
          total_pages: pos_integer(),
          events: list(Event)
        }
  defstruct [:current_page, :total_pages, :events]
end
