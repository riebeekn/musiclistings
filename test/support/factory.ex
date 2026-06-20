# credo:disable-for-this-file
defmodule MusicListings.Factory do
  use ExMachina.Ecto, repo: MusicListings.Repo

  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsSchema.Venue

  def crawl_summary_factory do
    %CrawlSummary{}
  end

  def event_factory do
    %Event{
      venue: build(:venue),
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
    }
  end

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

  def venue_factory do
    %Venue{
      name: sequence(:venue_name, &"Test Venue #{&1}"),
      pull_events?: true,
      include_in_recently_added_feed?: true,
      parser_module_name: "DanforthMusicHallParser",
      street: sequence(:venue_street, &"#{&1} Main Street"),
      city: "Toronto",
      province: "Ontario",
      country: "Canada",
      postal_code: "M5V 2T6",
      google_map_url: "https://maps.google.com/?q=43.6532,-79.3832"
    }
  end
end
