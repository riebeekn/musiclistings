defmodule MusicListings.Emails.NewThisWeekAnalyticsTest do
  use ExUnit.Case, async: true

  alias MusicListings.Emails.NewThisWeekAnalytics

  defp report(this_week, prior_week, opts \\ []) do
    %{
      period_end: ~U[2024-08-01 12:00:00Z],
      this_week_start: ~U[2024-07-25 12:00:00Z],
      prior_week_start: ~U[2024-07-18 12:00:00Z],
      this_week: this_week,
      prior_week: prior_week,
      this_week_conversions: Keyword.get(opts, :this_week_conversions, %{}),
      prior_week_conversions: Keyword.get(opts, :prior_week_conversions, %{}),
      this_week_ticket_shown: Keyword.get(opts, :this_week_ticket_shown, %{}),
      prior_week_ticket_shown: Keyword.get(opts, :prior_week_ticket_shown, %{})
    }
  end

  describe "new_email/1" do
    test "addresses the email to the site admin from no-reply" do
      email =
        %{"new_this_week.shown" => 100, "new_this_week.card_click" => 10}
        |> report(%{})
        |> NewThisWeekAnalytics.new_email()

      admin_email = Application.get_env(:music_listings, :admin_email)

      assert email.to == [{"", admin_email}]
      assert {"Toronto Music Listings", "no-reply@torontomusiclistings.com"} = email.from
    end

    test "summarises this week's views and clicks in the subject" do
      email =
        %{"new_this_week.shown" => 412, "new_this_week.card_click" => 63}
        |> report(%{"new_this_week.shown" => 349})
        |> NewThisWeekAnalytics.new_email()

      assert email.subject == "Rail Traction — 412 views, 63 clicks (last 7 days)"
    end

    test "renders both html and text bodies" do
      email =
        %{
          "new_this_week.shown" => 412,
          "new_this_week.card_click" => 63
        }
        |> report(%{
          "new_this_week.shown" => 349,
          "new_this_week.card_click" => 58
        })
        |> NewThisWeekAnalytics.new_email()

      assert email.html_body =~ "New This Week"
      assert email.html_body =~ "412"
      assert is_binary(email.text_body) and email.text_body != ""
    end

    test "renders without raising when there is no activity (zero denominators)" do
      email = %{} |> report(%{}) |> NewThisWeekAnalytics.new_email()

      assert email.subject == "Rail Traction — 0 views, 0 clicks (last 7 days)"
      # CTR / pct-change guards should produce n/a rather than crash on divide-by-zero
      assert email.html_body =~ "n/a"
    end

    test "measures rail conversion against ticket-eligible views, not raw card clicks" do
      email =
        %{
          "new_this_week.card_click" => 50,
          "event.ticket_click" => 44,
          "event.ticket_link_shown" => 200
        }
        |> report(
          %{"new_this_week.card_click" => 30},
          this_week_conversions: %{"new_this_week" => 10, nil => 34},
          prior_week_conversions: %{"new_this_week" => 6},
          # Only 40 of the 50 rail card clicks reached an event with a ticket link;
          # the other 10 can never convert and must not dilute the denominator.
          this_week_ticket_shown: %{"new_this_week" => 40, nil => 160}
        )
        |> NewThisWeekAnalytics.new_email()

      assert email.html_body =~ "Rail conversions"
      # Conversion = rail ticket clicks (10) / rail ticket-eligible views (40) = 25.0%,
      # NOT the misleading 10/50 = 20.0% against raw card clicks.
      assert email.html_body =~ "25.0%"
      refute email.html_body =~ "20.0%"
      # Overall event-page ticket CTR = 44 / 200 = 22.0% is a separate figure.
      assert email.html_body =~ "event-page ticket CTR"
      assert email.html_body =~ "22.0%"
    end

    test "renders the conversions section without raising when new fields are absent" do
      # Reports built before these fields existed (or with no activity) should
      # still render — the email defaults the maps to empty.
      email =
        %{"new_this_week.shown" => 5}
        |> report(%{})
        |> Map.drop([
          :this_week_conversions,
          :prior_week_conversions,
          :this_week_ticket_shown,
          :prior_week_ticket_shown
        ])
        |> NewThisWeekAnalytics.new_email()

      assert email.html_body =~ "Rail conversions"
    end
  end
end
