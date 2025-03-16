defmodule MusicListingsServices.EventSubmissionService do
  @moduledoc """
  Service module for handling functionality around submitted events
  """
  alias Ecto.Changeset
  alias MusicListings.Accounts.User
  alias MusicListings.Emails.NewSubmittedEvent
  alias MusicListings.Events
  alias MusicListings.Mailer
  alias MusicListings.Parsing.ParseHelpers
  alias MusicListings.Parsing.Price
  alias MusicListings.Repo
  alias MusicListings.Venues
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent

  @doc """
  Handles manual event submissions
  """
  @spec process_submitted_event(
          attrs :: %{
            title: String.t(),
            venue: String.t(),
            date: Date.t(),
            time: String.t(),
            price: String.t(),
            url: String.t()
          }
        ) :: {:ok, SubmittedEvent.t()} | {:error, Ecto.Changeset.t()}
  def process_submitted_event(attrs) do
    %SubmittedEvent{}
    |> Changeset.cast(attrs, [:title, :venue, :date, :time, :price, :url])
    |> Changeset.validate_required([:title, :venue, :date])
    |> Repo.insert()
    |> case do
      {:ok, submitted_event} ->
        submitted_event
        |> NewSubmittedEvent.new_email()
        |> Mailer.deliver()

        {:ok, submitted_event}

      error ->
        error
    end
  end

  @doc """
  Turns a submitted event into an event record
  """
  @spec approve_submitted_event(User, pos_integer()) :: {:ok, Event} | {:error, atom()}
  def approve_submitted_event(%User{role: :admin}, submitted_event_id) do
    with {:ok, submitted_event} <- Events.fetch_submitted_event(submitted_event_id),
         {:ok, venue} <- Venues.fetch_venue_by_name(submitted_event.venue) do
      external_id =
        "#{submitted_event.id}_#{ParseHelpers.build_id_from_title_and_date(submitted_event.title, submitted_event.date)}"

      price = parse_price_or_default_to_unknown(submitted_event.price)

      Repo.transaction(fn ->
        submitted_event
        |> Changeset.change(%{approved?: true})
        |> Repo.update!()

        %Event{
          external_id: external_id,
          venue_id: venue.id,
          title: submitted_event.title,
          headliner: submitted_event.title,
          openers: [],
          date: submitted_event.date,
          time: ParseHelpers.build_time_from_time_string(submitted_event.time),
          price_format: price.format,
          price_lo: price.lo,
          price_hi: price.hi,
          age_restriction: :unknown,
          details_url: submitted_event.url
        }
        |> Repo.insert!()
      end)
    end
  end

  def approve_submitted_event(_user, _submitted_event_id) do
    {:error, :not_allowed}
  end

  defp parse_price_or_default_to_unknown(price_string) do
    Price.new(price_string)
  rescue
    _parse_error -> Price.unknown()
  end
end
