defmodule MusicListings.Venues.VenueSummary do
  @moduledoc """
  Module to represent a venue summary
  """
  defstruct [:name, :street, :upcoming_event_count]

  def new(%{name: name, street: street, event_count: event_count}) do
    %__MODULE__{name: name, street: street, upcoming_event_count: event_count}
  end
end
