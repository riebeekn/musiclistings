defmodule MusicListings.EventsFixtures do
  @moduledoc false
  alias MusicListings.Repo
  alias MusicListingsSchema.Event

  def event_fixture(venue, attrs \\ %{}) do
    attrs = valid_event_attributes(venue, attrs)

    Repo.insert!(attrs)
  end

  defp valid_event_attributes(venue, attrs) do
    params =
      Enum.into(attrs, %{
        venue_id: venue.id,
        external_id: Ecto.UUID.generate(),
        title: "Bob Mintzer Quartet",
        headliner: "Bob Mintzer",
        openers: [],
        date: ~D[2024-04-02],
        time: ~T[20:00:00],
        price_format: :fixed,
        price_lo: 10.00,
        price_hi: 20.00,
        age_restriction: :all_ages,
        ticket_url: "https://tickets@example.com",
        details_url: "https://details@example.com"
      })

    Ecto.Changeset.cast(%Event{}, params, [
      :external_id,
      :venue_id,
      :title,
      :headliner,
      :openers,
      :date,
      :time,
      :price_format,
      :price_lo,
      :price_hi,
      :age_restriction,
      :ticket_url,
      :details_url
    ])
  end
end
