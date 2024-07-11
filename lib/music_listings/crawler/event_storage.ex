defmodule MusicListings.Crawler.EventStorage do
  @moduledoc """
  Takes in a list of payloads and persists them to the database
  if appropriate (duplicates / parse errors are ignored)
  """
  alias MusicListings.Crawler.Payload
  alias MusicListings.Repo
  alias MusicListingsSchema.Event

  @spec save_events(payloads :: list(Payload)) :: list(Payload)
  def save_events(payloads) do
    Enum.map(payloads, &save_event/1)
  end

  defp save_event(payload) do
    if payload.status == :ok do
      existing_event =
        Repo.get_by(Event,
          external_id: payload.parsed_event.external_id,
          venue_id: payload.parsed_event.venue_id
        )

      if existing_event do
        maybe_update_event(payload, existing_event)
      else
        insert_event(payload)
      end
    else
      # just ignore the payload in cases where the status is anything
      # but :ok... indicates a parse error
      payload
    end
  end

  defp insert_event(payload) do
    %{
      external_id: payload.parsed_event.external_id,
      venue_id: payload.parsed_event.venue_id,
      title: payload.parsed_event.title,
      headliner: payload.parsed_event.headliner,
      openers: payload.parsed_event.openers,
      date: payload.parsed_event.date,
      time: payload.parsed_event.time,
      price_format: payload.parsed_event.price_format,
      price_lo: payload.parsed_event.price_lo,
      price_hi: payload.parsed_event.price_hi,
      age_restriction: payload.parsed_event.age_restriction,
      source_url: payload.parsed_event.source_url,
      ticket_url: payload.parsed_event.ticket_url
    }
    |> Event.changeset()
    |> Repo.insert()
    |> case do
      {:ok, persisted_event} ->
        payload
        |> Payload.set_persisted_event(persisted_event)
        |> Payload.set_operation(:created)

      {:error, error} ->
        Payload.set_save_error(payload, error)
    end
  end

  defp maybe_update_event(payload, existing_event) do
    %{
      title: payload.parsed_event.title,
      headliner: payload.parsed_event.headliner,
      openers: payload.parsed_event.openers,
      date: payload.parsed_event.date,
      time: payload.parsed_event.time,
      price_format: payload.parsed_event.price_format,
      price_lo: payload.parsed_event.price_lo,
      price_hi: payload.parsed_event.price_hi,
      age_restriction: payload.parsed_event.age_restriction,
      source_url: payload.parsed_event.source_url,
      ticket_url: payload.parsed_event.ticket_url
    }
    |> Event.changeset(existing_event)
    |> maybe_update(payload)
  end

  defp maybe_update(%Ecto.Changeset{changes: changes, errors: errors}, payload)
       when changes == %{} and errors == [] do
    payload
    |> Payload.set_persisted_event(payload)
    |> Payload.set_operation(:noop)
  end

  defp maybe_update(changeset, payload) do
    changeset
    |> Repo.update()
    |> case do
      {:ok, persisted_event} ->
        payload
        |> Payload.set_persisted_event(persisted_event)
        |> Payload.set_operation(:updated)

      {:error, error} ->
        Payload.set_save_error(payload, error)
    end
  end
end
