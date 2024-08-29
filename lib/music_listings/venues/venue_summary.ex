defmodule MusicListings.Venues.VenueSummary do
  @moduledoc """
  Module to represent a venue summary
  """
  defstruct [:id, :name, :street, :upcoming_event_count]

  def new(%{id: id, name: name, street: street, event_count: event_count}) do
    %__MODULE__{id: id, name: name, street: street, upcoming_event_count: event_count}
  end
end
