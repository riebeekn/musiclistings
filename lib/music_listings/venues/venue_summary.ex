defmodule MusicListings.Venues.VenueSummary do
  @moduledoc """
  Module to represent a venue summary
  """
  defstruct [:id, :name, :street, :upcoming_event_count, pull_events?: true]

  def new(%{id: id, name: name, street: street, event_count: event_count} = summary) do
    %__MODULE__{
      id: id,
      name: name,
      street: street,
      upcoming_event_count: event_count,
      pull_events?: Map.get(summary, :pull_events?, true)
    }
  end
end
