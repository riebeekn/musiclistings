defmodule MusicListings.Emails.NewSubmittedEvent do
  @moduledoc """
  Email that gets sent when an event is submitted
  """
  use MusicListings.Mailer

  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsUtilities.DateHelpers

  def new_email(submitted_event) do
    new()
    |> to_site_admin()
    |> from_noreply()
    |> subject("New Submitted Event: #{submitted_event.title}")
    |> body(mjml(%{submitted_event: submitted_event}))
  end

  defp mjml(assigns) do
    ~H"""
    <.h1>New Event Submitted</.h1>
    <.muted>
      Submitted {formatted_submitted_at(@submitted_event.inserted_at)} ·
      <.badge>Needs review</.badge>
    </.muted>

    <.h2>{@submitted_event.title}</.h2>

    <.details>
      <:item label="Venue">{value_or_dash(@submitted_event.venue)}</:item>
      <:item label="Date">{formatted_event_date(@submitted_event.date)}</:item>
      <:item label="Time">{value_or_dash(@submitted_event.time)}</:item>
      <:item label="Price">{value_or_dash(@submitted_event.price)}</:item>
      <:item label="Link">
        <%= if present?(@submitted_event.url) do %>
          <a href={@submitted_event.url} style="color:#d8ff3e;text-decoration:none;">
            {@submitted_event.url}
          </a>
        <% else %>
          —
        <% end %>
      </:item>
      <:item label="Ref">#{@submitted_event.id}</:item>
    </.details>

    <%= if present?(@submitted_event.url) do %>
      <.button href={@submitted_event.url}>View event page →</.button>
    <% end %>
    """
  end

  defp formatted_submitted_at(datetime) do
    datetime
    |> DateHelpers.to_eastern_datetime()
    |> Calendar.strftime("%b %-d, %Y · %-I:%M %p %Z")
  end

  defp formatted_event_date(%Date{} = date), do: DateHelpers.format_date(date)
  defp formatted_event_date(_other), do: "—"

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp value_or_dash(value) do
    if present?(value), do: value, else: "—"
  end

  def preview do
    %SubmittedEvent{
      id: 123,
      title: "The Fixies: no.1 female led Pixies tribute band",
      venue: "The Rock Station",
      date: ~D[2024-01-17],
      time: "doors 7pm, show at 8",
      price: "$35",
      url: "https://example.com/the-fixies",
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
