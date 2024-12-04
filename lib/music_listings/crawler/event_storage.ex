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
      save_parsed_event(payload, payload.parsed_event)
    else
      # just ignore the payload in cases where the status is anything
      # but :ok... indicates a parse error
      payload
    end
  end

  defp save_parsed_event(payload, parsed_event) when is_list(parsed_event) do
    Enum.map(parsed_event, &save_parsed_event(payload, &1))
  end

  defp save_parsed_event(payload, parsed_event) do
    parsed_event.external_id

    existing_event =
      Repo.get_by(Event,
        external_id: parsed_event.external_id,
        venue_id: parsed_event.venue_id
      )

    if existing_event do
      maybe_update_event(payload, parsed_event, existing_event)
    else
      insert_event(payload, parsed_event)
    end
  end

  defp insert_event(payload, parsed_event) do
    persisted_event =
      %{
        external_id: parsed_event.external_id,
        venue_id: parsed_event.venue_id,
        title: parsed_event.title,
        headliner: parsed_event.headliner,
        openers: parsed_event.openers,
        date: parsed_event.date,
        time: parsed_event.time,
        price_format: parsed_event.price_format,
        price_lo: parsed_event.price_lo,
        price_hi: parsed_event.price_hi,
        age_restriction: parsed_event.age_restriction,
        ticket_url: parsed_event.ticket_url,
        details_url: parsed_event.details_url
      }
      |> event_changeset()
      |> Repo.insert!()

    payload
    |> Payload.set_persisted_event(persisted_event)
    |> Payload.set_operation(:created)
  end

  defp maybe_update_event(payload, parsed_event, existing_event) do
    %{
      title: parsed_event.title,
      headliner: parsed_event.headliner,
      openers: parsed_event.openers,
      date: parsed_event.date,
      time: parsed_event.time,
      price_format: parsed_event.price_format,
      price_lo: parsed_event.price_lo,
      price_hi: parsed_event.price_hi,
      age_restriction: parsed_event.age_restriction,
      ticket_url: parsed_event.ticket_url,
      details_url: parsed_event.details_url
    }
    |> event_changeset(existing_event)
    |> maybe_update(payload)
  end

  defp maybe_update(%Ecto.Changeset{changes: changes, errors: errors}, payload)
       when changes == %{} and errors == [] do
    payload
    |> Payload.set_persisted_event(payload)
    |> Payload.set_operation(:noop)
  end

  defp maybe_update(changeset, payload) do
    persisted_event =
      changeset
      |> Repo.update!()

    payload
    |> Payload.set_persisted_event(persisted_event)
    |> Payload.set_operation(:updated)
  end

  defp event_changeset(attrs, event \\ %Event{}) do
    event
    |> Ecto.Changeset.cast(attrs, [
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
