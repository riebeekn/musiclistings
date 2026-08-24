defmodule MusicListings.Events.EventSuggestion do
  @moduledoc """
  Struct to represent a single search typeahead suggestion
  """

  @type t :: %__MODULE__{
          event_id: pos_integer(),
          title: String.t(),
          date: Date.t(),
          venue_name: String.t(),
          openers: [String.t()]
        }

  defstruct [:event_id, :title, :date, :venue_name, openers: []]
end
