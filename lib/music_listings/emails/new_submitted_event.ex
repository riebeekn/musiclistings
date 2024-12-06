defmodule MusicListings.Emails.NewSubmittedEvent do
  @moduledoc """
  Email that gets sent when an event is submitted
  """
  use MjmlEEx,
    mjml_template: "templates/new_submitted_event.mjml.eex",
    layout: MusicListings.Emails.BaseLayout

  alias Swoosh.Email

  alias MusicListingsSchema.SubmittedEvent

  def new(submitted_event) do
    body = __MODULE__.render(%{submitted_event: submitted_event})
    text_body = body |> Premailex.to_text()

    Email.new()
    |> Email.to(Application.get_env(:music_listings, :admin_email))
    |> Email.from({"Toronto Music Listings", "no-reply@torontomusiclistings.com"})
    |> Email.subject("New Submitted Event")
    |> Email.html_body(body)
    |> Email.text_body(text_body)
  end

  def preview do
    %SubmittedEvent{
      id: 123,
      title: "The Fixies: no.1 female led Pixies tribute band",
      venue: "The Rock Station",
      date: ~D[2024-01-17],
      time: "doors 7pm, show at 8",
      price: "$35",
      url: "example.com",
      inserted_at: ~U[2024-01-02 16:53:02.847841Z]
    }
    |> new()
  end

  def preview_details do
    [
      title: "New Event Submitted",
      description: "Sent when a new event is submitted",
      tags: [category: "Admin"]
    ]
  end
end
