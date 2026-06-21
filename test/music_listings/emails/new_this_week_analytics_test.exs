defmodule MusicListings.Emails.NewThisWeekAnalyticsTest do
  use ExUnit.Case, async: true

  alias MusicListings.Emails.NewThisWeekAnalytics

  defp report(this_week, prior_week) do
    %{
      period_end: ~U[2024-08-01 12:00:00Z],
      this_week_start: ~U[2024-07-25 12:00:00Z],
      prior_week_start: ~U[2024-07-18 12:00:00Z],
      this_week: this_week,
      prior_week: prior_week
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
          "new_this_week.card_click" => 63,
          "new_this_week.ticket_click" => 21
        }
        |> report(%{
          "new_this_week.shown" => 349,
          "new_this_week.card_click" => 58,
          "new_this_week.ticket_click" => 22
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
  end
end
