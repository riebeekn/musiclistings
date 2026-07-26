defmodule MusicListings.Emails.LatestCrawlResultsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Affiliates.TicketNetwork
  alias MusicListings.Emails.LatestCrawlResults
  alias MusicListingsSchema.CrawlError
  alias MusicListingsSchema.CrawlSummary
  alias MusicListingsSchema.VenueCrawlSummary
  alias MusicListingsUtilities.DateHelpers

  # The crawl summary row is written when the crawl starts, so events inserted
  # after it are the ones that crawl created. Back-date it so events inserted by
  # these tests fall inside the window. Anchor to DateHelpers.now/0, not the wall
  # clock - the schema autogenerates timestamps from it and it is frozen in test.
  defp crawl_started_at, do: DateHelpers.now() |> DateTime.add(-60, :second)

  defp crawl_summary(crawl_errors) do
    venue_crawl_summaries =
      crawl_errors
      |> Enum.map(& &1.venue)
      |> Enum.uniq_by(& &1.id)
      |> Enum.map(fn venue ->
        %VenueCrawlSummary{
          venue: venue,
          venue_id: venue.id,
          new: 0,
          updated: 0,
          duplicate: 0,
          ignored: 0,
          errors: 0
        }
      end)

    %CrawlSummary{
      id: 1,
      new: 0,
      updated: 0,
      duplicate: 0,
      ignored: 0,
      errors: Enum.count(crawl_errors),
      inserted_at: crawl_started_at(),
      crawl_errors: crawl_errors,
      venue_crawl_summaries: venue_crawl_summaries
    }
  end

  defp no_events_error(venue) do
    %CrawlError{
      id: venue.id,
      venue: venue,
      venue_id: venue.id,
      type: :no_events_error,
      error: "No events found for #{venue.name}"
    }
  end

  defp parse_error(venue) do
    %CrawlError{
      id: 2,
      venue: venue,
      venue_id: venue.id,
      type: :parse_error,
      error: "** (FunctionClauseError) no function clause matching",
      raw_event: "<article id=\"post-8043\">raw event markup</article>"
    }
  end

  describe "new_email/1 - no events found" do
    test "hands over the local crawl command, keyed by parser module name" do
      venue = insert(:venue, parser_module_name: "BlockedVenueParser")

      email = [no_events_error(venue)] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "Crawl locally"
      assert email.html_body =~ "bin/crawl-venue.sh BlockedVenueParser"
      refute email.html_body =~ "Raw event"
    end

    test "rolls every empty venue into a single command, sorted by venue name" do
      zulu = insert(:venue, name: "Zulu Test Hall", parser_module_name: "ZuluParser")
      alpha = insert(:venue, name: "Alpha Test Hall", parser_module_name: "AlphaParser")

      email =
        [no_events_error(zulu), no_events_error(alpha)]
        |> crawl_summary()
        |> LatestCrawlResults.new_email()

      assert email.html_body =~ "bin/crawl-venue.sh AlphaParser ZuluParser"
      # one command, not one per venue
      assert email.html_body |> String.split("bin/crawl-venue.sh") |> length() == 2
    end

    test "omits the section when no venue came up empty" do
      venue = insert(:venue)

      email = [parse_error(venue)] |> crawl_summary() |> LatestCrawlResults.new_email()

      refute email.html_body =~ "Crawl locally"
    end
  end

  describe "new_email/1 - other error types" do
    test "renders the raw event and not a crawl command" do
      venue = insert(:venue, parser_module_name: "SomeVenueParser")

      email = [parse_error(venue)] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "Raw event"
      assert email.html_body =~ "raw event markup"
      refute email.html_body =~ "bin/crawl-venue.sh"
      refute email.html_body =~ "Crawl locally"
    end
  end

  describe "new_email/1 - new events" do
    test "lists the events added by the crawl, sorted by venue" do
      zulu = insert(:venue, name: "Zulu Test Hall")
      alpha = insert(:venue, name: "Alpha Test Hall")

      insert(:event, venue: zulu, title: "Sunset Rubdown", date: ~D[2026-08-14])
      insert(:event, venue: alpha, title: "Badge Epoque Ensemble", date: ~D[2026-08-21])

      email = [] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "New events (2)"
      assert email.html_body =~ "Sunset Rubdown"
      assert email.html_body =~ "Badge Epoque Ensemble"
      assert email.html_body =~ DateHelpers.format_date(~D[2026-08-14])

      # sorted by venue name, so Alpha Test Hall comes before Zulu Test Hall
      {alpha_at, _length} = :binary.match(email.html_body, "Badge Epoque Ensemble")
      {zulu_at, _length} = :binary.match(email.html_body, "Sunset Rubdown")
      assert alpha_at < zulu_at
    end

    test "omits events that predate the crawl" do
      venue = insert(:venue)

      old_event =
        insert(:event,
          venue: venue,
          title: "Already Known Show",
          inserted_at: DateHelpers.now() |> DateTime.add(-1, :day)
        )

      insert(:event, venue: venue, title: "Brand New Show")

      email = [] |> crawl_summary() |> LatestCrawlResults.new_email()

      assert email.html_body =~ "New events (1)"
      assert email.html_body =~ "Brand New Show"
      refute email.html_body =~ old_event.title
    end

    test "omits the section entirely when nothing was added" do
      email = [] |> crawl_summary() |> LatestCrawlResults.new_email()

      refute email.html_body =~ "New events"
    end
  end

  describe "new_email/3 - TicketNetwork consecutive-night runs" do
    defp ticket_network_stats(runs, venue) do
      %TicketNetwork.Stats{
        matched: 596,
        linked: 100,
        cleared: 0,
        unmatched_items: 65,
        untracked_items: 68,
        venue_names: %{venue.id => venue.name},
        consecutive_runs: runs
      }
    end

    defp runs_email(runs) do
      venue = insert(:venue, name: "Roy Test Hall")

      runs = Enum.map(runs, &Map.put(&1, :venue_id, venue.id))

      []
      |> crawl_summary()
      |> LatestCrawlResults.new_email(nil, ticket_network_stats(runs, venue))
    end

    test "renders a run's nights as a date range" do
      email =
        runs_email([
          %{title: "TSO - Messiah", dates: [~D[2026-12-18], ~D[2026-12-19], ~D[2026-12-20]]}
        ])

      assert email.html_body =~ "TSO - Messiah"
      assert email.html_body =~ "Dec 18 - 20 2026"
    end

    # The whole email is one fixed-width column, so an unbreakable cell doesn't
    # just widen its own table - it stretches the message past the body width
    # and pushes every table's right-hand columns out of view.
    test "leaves no unbreakable run of dates wide enough to stretch the email" do
      email =
        runs_email([
          %{
            title: "National Geographic Live: Chris Schell",
            dates:
              [~D[2026-11-08], ~D[2026-11-09], ~D[2026-11-10]] ++
                [~D[2027-03-21], ~D[2027-03-22], ~D[2027-03-23]] ++
                [~D[2027-04-18], ~D[2027-04-19], ~D[2027-04-20]] ++
                [~D[2027-05-30], ~D[2027-05-31], ~D[2027-06-01]]
          }
        ])

      assert email.html_body =~ "Nov 08 - 10 2026"
      assert email.html_body =~ "May 30 - Jun 01 2027"

      longest =
        ~r/white-space:nowrap[^>]*>([^<]*)</
        |> Regex.scan(email.html_body, capture: :all_but_first)
        |> List.flatten()
        |> Enum.map(&(&1 |> String.replace(~r/\s+/, " ") |> String.trim() |> String.length()))
        |> Enum.max()

      assert longest <= 40
    end

    test "omits the runs table when the crawl found no runs" do
      email = runs_email([])

      assert email.html_body =~ "TicketNetwork affiliate links"
      refute email.html_body =~ "Consecutive-night runs"
    end
  end

  describe "new_email/3 - TicketNetwork failures" do
    defp result_email(result) do
      [] |> crawl_summary() |> LatestCrawlResults.new_email(nil, result)
    end

    # A timeout used to render exactly like a night with nothing to report.
    test "reports a timed-out catalog" do
      email = result_email({:error, %Req.TransportError{reason: :timeout}})

      assert email.html_body =~ "TicketNetwork affiliate links"
      assert email.html_body =~ "Matching did not run"
      assert email.html_body =~ "timed out"
      assert email.html_body =~ "Existing affiliate links are untouched"
    end

    test "reports an unexpected status" do
      email = result_email({:error, {:unexpected_status, 401}})

      assert email.html_body =~ "Matching did not run"
      assert email.html_body =~ "HTTP 401"
    end

    test "reports a crash" do
      email = result_email({:error, %RuntimeError{message: "boom"}})

      assert email.html_body =~ "Matching did not run"
      assert email.html_body =~ "boom"
    end

    # No credentials is the normal state in dev, not something to report.
    test "says nothing when the pass was skipped or never ran" do
      for result <- [:skipped, nil] do
        email = result_email(result)

        refute email.html_body =~ "TicketNetwork affiliate links"
        refute email.html_body =~ "Matching did not run"
      end
    end
  end
end
