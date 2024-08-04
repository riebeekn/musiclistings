defmodule MusicListings.Repo do
  use Ecto.Repo,
    otp_app: :music_listings,
    adapter: Ecto.Adapters.Postgres

  use Scrivener
end
