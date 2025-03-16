defmodule MusicListingsServices.EventSubmissionServiceTest do
  use MusicListings.DataCase, async: true

  import Swoosh.TestAssertions

  alias MusicListings.Accounts.User
  alias MusicListings.SubmittedEventsFixtures
  alias MusicListings.VenuesFixtures
  alias MusicListingsSchema.Event
  alias MusicListingsSchema.SubmittedEvent
  alias MusicListingsServices.EventSubmissionService

  describe "process_submitted_event/1" do
    test "with valid attributes creates a submitted event" do
      assert {:ok,
              %SubmittedEvent{
                title: "Event title",
                venue: "The Venue",
                date: ~D[2024-01-17],
                time: nil,
                price: nil,
                url: nil
              }} =
               EventSubmissionService.process_submitted_event(%{
                 title: "Event title",
                 venue: "The Venue",
                 date: ~D[2024-01-17]
               })

      assert_email_sent(subject: "New Submitted Event")
    end

    test "returns a changeset with invalid attributes" do
      assert {:error, changeset} = EventSubmissionService.process_submitted_event(%{})

      assert errors_on(changeset) == %{
               date: ["can't be blank"],
               title: ["can't be blank"],
               venue: ["can't be blank"]
             }

      refute_email_sent()
    end
  end

  describe "approve_submitted_event/1" do
    setup do
      venue = VenuesFixtures.venue_fixture(%{name: "My Music Venue"})
      submitted_event = SubmittedEventsFixtures.submitted_event_fixture(venue.name)

      %{venue: venue, submitted_event: submitted_event}
    end

    test "with valid submission populates and event and flags submission as approved", %{
      venue: venue,
      submitted_event: submitted_event
    } do
      assert {:ok, event} =
               EventSubmissionService.approve_submitted_event(
                 %User{role: :admin},
                 submitted_event.id
               )

      venue_id = venue.id
      external_id = "#{submitted_event.id}_bob_mintzer_quartet_2024_04_02"
      title = submitted_event.title
      price_lo = Decimal.new("20.00")
      price_hi = Decimal.new("30.00")
      url = submitted_event.url

      assert %Event{
               external_id: ^external_id,
               title: ^title,
               headliner: ^title,
               openers: [],
               date: ~D[2024-04-02],
               time: ~T[19:30:00],
               price_format: :range,
               price_lo: ^price_lo,
               price_hi: ^price_hi,
               age_restriction: :unknown,
               ticket_url: nil,
               details_url: ^url,
               deleted_at: nil,
               venue_id: ^venue_id
             } = event

      submitted_event = Repo.reload(submitted_event)
      assert true = submitted_event.approved?
    end

    test "returns error when no user", %{submitted_event: submitted_event} do
      assert {:error, :not_allowed} ==
               EventSubmissionService.approve_submitted_event(nil, submitted_event.id)
    end

    test "returns error when user not an admin", %{submitted_event: submitted_event} do
      assert {:error, :not_allowed} ==
               EventSubmissionService.approve_submitted_event(
                 %User{role: :regular_user},
                 submitted_event.id
               )
    end

    test "returns an error when submitted event not found" do
      assert {:error, :submitted_event_not_found} ==
               EventSubmissionService.approve_submitted_event(%User{role: :admin}, -1)
    end

    test "returns an error when venue not found", %{
      venue: venue,
      submitted_event: submitted_event
    } do
      Repo.delete!(venue)

      assert {:error, :venue_not_found} ==
               EventSubmissionService.approve_submitted_event(
                 %User{role: :admin},
                 submitted_event.id
               )
    end

    test "with invalid price defaults to unknown price", %{submitted_event: submitted_event} do
      submitted_event =
        submitted_event
        |> Ecto.Changeset.change(%{price: "this isn't a valid price string!"})
        |> Repo.update!()

      assert {:ok, event} =
               EventSubmissionService.approve_submitted_event(
                 %User{role: :admin},
                 submitted_event.id
               )

      assert %Event{
               price_format: :unknown,
               price_lo: nil,
               price_hi: nil
             } = event
    end
  end
end
