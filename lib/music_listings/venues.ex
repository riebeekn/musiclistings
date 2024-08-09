defmodule MusicListings.Venues do
  @moduledoc """
  Context module for venue related functionality
  """

  alias MusicListings.Repo
  alias MusicListingsSchema.Venue

  @spec get_venue!(pos_integer()) :: Venue
  def get_venue!(venue_id), do: Repo.get!(Venue, venue_id)
end
