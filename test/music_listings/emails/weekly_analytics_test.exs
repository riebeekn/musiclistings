defmodule MusicListings.Emails.WeeklyAnalyticsTest do
  use ExUnit.Case, async: true

  alias MusicListings.Emails.WeeklyAnalytics

  defp report(overrides \\ []) do
    Map.merge(
      %{
        period_end: ~U[2024-08-01 12:00:00Z],
        this_week_start: ~U[2024-07-25 12:00:00Z],
        prior_week_start: ~U[2024-07-18 12:00:00Z],
        this_week: %{clicks: 0, impressions: 0},
        prior_week: %{clicks: 0, impressions: 0},
        baseline: %{clicks: 0.0, impressions: 0.0},
        baseline_weeks: 4,
        top_venues: [],
        top_events: [],
        ticket_coverage: %{total: 0, with_ticket_link: 0},
        prior_ticket_coverage: nil,
        ticket_coverage_by_venue: [],
        coverage_drops: nil,
        coverage_drop_threshold: 0.10
      },
      Map.new(overrides)
    )
  end

  describe "new_email/1" do
    test "reports the ticket CTR against the prior week's, not just the click count" do
      # Clicks rose 50% here while the rate fell, because the impression base
      # nearly doubled - which is what happens the week ticket links are added to
      # a batch of venues. Reporting clicks alone reads that as engagement growth.
      email =
        [
          this_week: %{clicks: 150, impressions: 2000},
          prior_week: %{clicks: 100, impressions: 1000}
        ]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.html_body =~ "7.5%"
      assert email.html_body =~ "10.0%"
      assert email.html_body =~ "-2.5 pts"
      assert email.html_body =~ "Ticket link impressions"
      assert email.text_body =~ "2000"
      assert email.text_body =~ "1000"
    end

    test "takes the CTR change between the rounded rates shown" do
      # 10.66% vs 10.94% - shown as 10.7% and 10.9%. The unrounded change is
      # -0.28, which would read -0.3 pts beside figures 0.2 apart.
      email =
        [
          this_week: %{clicks: 1066, impressions: 10_000},
          prior_week: %{clicks: 1094, impressions: 10_000}
        ]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.html_body =~ "10.7%"
      assert email.html_body =~ "10.9%"
      assert email.html_body =~ "-0.2 pts"
      refute email.html_body =~ "-0.3 pts"
    end

    test "shows the top event's share of clicks, and the week without it" do
      email =
        [
          this_week: %{clicks: 780, impressions: 7319},
          prior_week: %{clicks: 726, impressions: 6656},
          baseline: %{clicks: 678.0, impressions: 6199.0},
          top_events: [
            %{id: 1, title: "Big Show", date: ~D[2024-08-10], venue_name: "Hall", clicks: 132},
            %{id: 2, title: "Small Show", date: ~D[2024-08-11], venue_name: "Bar", clicks: 10}
          ]
        ]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.text_body =~ "The top event, Big Show, drew 132 of the week's 780 clicks (17%)"
      assert email.text_body =~ "Without it the week had 648 clicks, against 726 the prior week"
      assert email.text_body =~ "4-week average of 678"
    end

    test "leaves out the top event's share when there are no clicks" do
      email = WeeklyAnalytics.new_email(report())

      refute email.html_body =~ "The top event"
    end

    test "lists venues whose ticket-link coverage fell" do
      email =
        [
          coverage_drops: [
            %{
              venue_name: "Horseshoe Tavern",
              prior: %{total: 40, with_ticket_link: 38},
              current: %{total: 44, with_ticket_link: 22}
            }
          ]
        ]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.html_body =~ "fell by 10 pts or more"
      assert email.html_body =~ "Horseshoe Tavern"
      assert email.html_body =~ "95.0% (38/40)"
      assert email.html_body =~ "50.0% (22/44)"
      assert email.html_body =~ "-45.0 pts"
    end

    test "says when no venue's coverage fell" do
      email =
        [coverage_drops: []]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.text_body =~ "No venue's coverage fell by 10 pts or more"
    end

    test "says per-venue coverage starts next report when there is no per-venue snapshot" do
      email = WeeklyAnalytics.new_email(report())

      assert email.html_body =~ "Per-venue coverage changes start with the next report."
    end

    test "shows the multi-week average alongside the prior week" do
      email =
        [
          this_week: %{clicks: 80, impressions: 1000},
          baseline: %{clicks: 66.5, impressions: 1745.25}
        ]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.html_body =~ "4-wk avg"
      assert email.html_body =~ "67"
      assert email.html_body =~ "1745"
      # baseline CTR = 66.5 / 1745.25
      assert email.html_body =~ "3.8%"
    end

    test "summarises ticket clicks and CTR in the subject" do
      email =
        [this_week: %{clicks: 74, impressions: 1850}]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.subject == "Weekly Analytics — 74 ticket clicks, 4.0% CTR (last 7 days)"
    end

    test "reports ticket-link coverage against the last snapshot" do
      email =
        [
          ticket_coverage: %{total: 1000, with_ticket_link: 750},
          prior_ticket_coverage: %{total: 1000, with_ticket_link: 800}
        ]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.html_body =~ "Ticket link coverage"
      assert email.html_body =~ "75.0%"
      assert email.html_body =~ "80.0%"
      assert email.html_body =~ "-5.0 pts"
    end

    test "says when there is no earlier coverage snapshot" do
      email =
        [ticket_coverage: %{total: 10, with_ticket_link: 5}]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.html_body =~ "No earlier snapshot"
    end

    test "lists the top venues and events by ticket clicks" do
      email =
        [
          top_venues: [%{venue_name: "Horseshoe Tavern", clicks: 12}],
          top_events: [
            %{
              id: 42,
              title: "Big Headliner",
              date: ~D[2024-08-10],
              venue_name: "Horseshoe Tavern",
              clicks: 7
            }
          ]
        ]
        |> report()
        |> WeeklyAnalytics.new_email()

      assert email.html_body =~ "Top venues"
      assert email.html_body =~ "Horseshoe Tavern"
      assert email.html_body =~ "Big Headliner"
      assert email.html_body =~ "/events/42"
      assert email.html_body =~ "Sat, Aug 10 2024"
    end

    test "no longer reports the rail or resale clicks" do
      email = WeeklyAnalytics.new_email(report())

      refute email.html_body =~ "New This Week"
      refute email.html_body =~ "Resale"
    end

    test "addresses the email to the site admin from no-reply" do
      email = WeeklyAnalytics.new_email(report())

      admin_email = Application.get_env(:music_listings, :admin_email)

      assert email.to == [{"", admin_email}]
      assert {"Toronto Music Listings", "no-reply@torontomusiclistings.com"} = email.from
    end

    test "renders without raising when there is no activity (zero denominators)" do
      email = WeeklyAnalytics.new_email(report())

      assert email.subject == "Weekly Analytics — 0 ticket clicks, n/a CTR (last 7 days)"
      # CTR / pct-change guards should produce n/a rather than crash on divide-by-zero
      assert email.html_body =~ "n/a"
      assert email.html_body =~ "No ticket clicks this week."
      assert is_binary(email.text_body) and email.text_body != ""
    end
  end
end
