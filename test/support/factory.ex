# credo:disable-for-this-file
defmodule MusicListings.Factory do
  use ExMachina.Ecto, repo: MusicListings.Repo

  alias MusicListingsSchema.SubmittedEvent

  def submitted_event_factory do
    %SubmittedEvent{
      title: "Bob Mintzer Quartet",
      venue: "The Village Vanguard",
      date: "2024-04-02",
      time: "7:30 PM",
      price: "$20.00 - $30.00",
      url: "https://tickets@example.com",
      approved?: false
    }
  end
end
