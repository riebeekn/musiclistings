defmodule MusicListings.VenuesFixtures do
  @moduledoc false
  alias MusicListings.Repo
  alias MusicListingsSchema.Venue

  def venue_fixture(attrs \\ %{}) do
    attrs = valid_venue_attributes(attrs)

    Repo.insert!(attrs)
  end

  defp valid_venue_attributes(attrs) do
    params =
      Enum.into(attrs, %{
        name: "The Danforth Music Hall",
        pull_events?: true,
        parser_module_name: "DanforthMusicHallParser"
      })

    Ecto.Changeset.cast(%Venue{}, params, [
      :name,
      :pull_events?,
      :parser_module_name
    ])
  end
end
