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
      name: Faker.Lorem.sentence(),
      pull_events?: true,
      parser_module_name: "DanforthMusicHallParser",
      street: Faker.Address.street_address(),
      city: Faker.Address.city(),
      province: "Ontario",
      country: "Canada",
      postal_code: Faker.Address.postcode(),
      google_map_url: Faker.Internet.image_url()
    }
  end
end
