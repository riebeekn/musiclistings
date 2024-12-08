defmodule MusicListings.Emails.NewSubmittedEvent do
  @moduledoc """
  Email that gets sent when an event is submitted
  """
  use MusicListings.Mailer

  alias MusicListingsSchema.SubmittedEvent

  def new_email(submitted_event) do
    new()
    |> to_site_admin()
    |> from_noreply()
    |> subject("New Submitted Event")
    |> body(mjml(%{submitted_event: submitted_event}))
  end

  defp mjml(assigns) do
    ~H"""
    <.h1>
      New Submitted Event - {DateTime.to_string(@submitted_event.inserted_at)}
    </.h1>
    <.text><b>Id: </b>{@submitted_event.id}</.text>
    <.text><b>Event title: </b>{@submitted_event.title}</.text>
    <.text><b>Venue: </b>{@submitted_event.venue}</.text>
    <.text><b>Date: </b>{@submitted_event.date}</.text>
    <.text><b>Time: </b>{@submitted_event.time}</.text>
    <.text><b>Price: </b>{@submitted_event.price}</.text>
    <.text><b>URL: </b>{@submitted_event.url}</.text>
    """
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
    |> new_email()
  end

  def preview_details do
    [
      title: "New Event Submitted",
      description: "Sent when a new event is submitted",
      tags: [category: "Admin"]
    ]
  end
end
