defmodule MusicListings.SubmittedEventsFixtures do
  @moduledoc false
  alias MusicListings.Repo
  alias MusicListingsSchema.SubmittedEvent

  def submitted_event_fixture(venue_name, attrs \\ %{}) do
    attrs = valid_event_attributes(venue_name, attrs)

    Repo.insert!(attrs)
  end

  defp valid_event_attributes(venue_name, attrs) do
    params =
      Enum.into(attrs, %{
        title: "Bob Mintzer Quartet",
        venue: venue_name,
        date: "2024-04-02",
        time: "7:30 PM",
        price: "$20.00 - $30.00",
        url: "https://tickets@example.com",
        approved?: false
      })

    Ecto.Changeset.cast(%SubmittedEvent{}, params, [
      :title,
      :venue,
      :date,
      :time,
      :price,
      :url,
      :approved?
    ])
  end
end
