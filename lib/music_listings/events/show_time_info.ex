defmodule MusicListings.Events.ShowTimeInfo do
  @moduledoc """
  Struct to represent a show time for an event
  """

  @type t :: %__MODULE__{
          event_id: pos_integer(),
          time: Time.t(),
          ticket_url: String.t(),
          details_url: String.t()
        }

  defstruct [:event_id, :time, :ticket_url, :details_url]
end
