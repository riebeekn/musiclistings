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
        name: Faker.Lorem.sentence(),
        pull_events?: true,
        parser_module_name: "DanforthMusicHallParser",
        street: Faker.Address.street_address(),
        city: Faker.Address.city(),
        province: "Ontario",
        country: "Canada",
        postal_code: Faker.Address.postcode(),
        google_map_url: Faker.Internet.image_url()
      })

    Ecto.Changeset.cast(%Venue{}, params, [
      :name,
      :pull_events?,
      :parser_module_name,
      :street,
      :city,
      :province,
      :country,
      :postal_code,
      :google_map_url
    ])
  end
end
