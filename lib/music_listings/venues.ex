defmodule MusicListings.Venues do
  @moduledoc """
  Context module for venue related functionality
  """
  import Ecto.Query

  alias MusicListings.Repo
  alias MusicListings.Venues.VenueSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.Venue
  alias MusicListingsUtilities.DateHelpers

  @spec list_venues :: list(VenueSummary)
  def list_venues do
    today = DateHelpers.now() |> DateHelpers.to_eastern_date()

    from(venue in Venue,
      left_join: event in Event,
      on: event.venue_id == venue.id and event.date >= ^today,
      group_by: [venue.id, venue.name, venue.street],
      order_by: venue.name,
      select: %{
        id: venue.id,
        name: venue.name,
        street: venue.street,
        event_count: count(event.id)
      }
    )
    |> Repo.all()
    |> Enum.map(&VenueSummary.new/1)
  end

  @spec get_venue!(pos_integer()) :: Venue
  def get_venue!(venue_id), do: Repo.get!(Venue, venue_id)
end
