defmodule MusicListings.Emails.ParserPullbackTest do
  use ExUnit.Case, async: true

  alias MusicListings.Emails.ParserPullback

  defp base_report(overrides) do
    Map.merge(
      %{
        reference: ~U[2024-08-01 12:00:00Z],
        lookback_days: 35,
        recent_crawls: 3,
        evaluated_count: 0,
        healthy_count: 0,
        flagged: []
      },
      overrides
    )
  end

  defp flagged_venue(overrides) do
    Map.merge(
      %{
        venue_name: "The Phoenix",
        baseline_yield: 42,
        recent_yield: 0,
        drop_pct: 1.0,
        recent_errors: 0,
        last_crawled_at: ~U[2024-07-31 09:00:00Z]
      },
      overrides
    )
  end

  describe "new_email/1" do
    test "addresses the email to the site admin from no-reply" do
      email = base_report(%{evaluated_count: 12, healthy_count: 12}) |> ParserPullback.new_email()

      admin_email = Application.get_env(:music_listings, :admin_email)
      assert email.to == [{"", admin_email}]
      assert {"Toronto Music Listings", "no-reply@torontomusiclistings.com"} = email.from
    end

    test "uses an all-clear subject when nothing is flagged" do
      email = base_report(%{evaluated_count: 12, healthy_count: 12}) |> ParserPullback.new_email()

      assert email.subject == "Parser Health — all clear (12 venues)"
      assert email.html_body =~ "no pullbacks detected"
    end

    test "summarises the flagged venue count in the subject" do
      report =
        base_report(%{
          evaluated_count: 12,
          healthy_count: 11,
          flagged: [flagged_venue(%{})]
        })

      email = ParserPullback.new_email(report)

      assert email.subject == "Parser Health — 1 venue may have pulled back"
    end

    test "renders the flagged venues table in the body" do
      report =
        base_report(%{
          evaluated_count: 12,
          healthy_count: 10,
          flagged: [
            flagged_venue(%{venue_name: "The Phoenix", drop_pct: 1.0}),
            flagged_venue(%{
              venue_name: "Horseshoe",
              baseline_yield: 18,
              recent_yield: 5,
              drop_pct: 0.72,
              recent_errors: 2
            })
          ]
        })

      email = ParserPullback.new_email(report)

      assert email.subject == "Parser Health — 2 venues may have pulled back"
      assert email.html_body =~ "The Phoenix"
      assert email.html_body =~ "Horseshoe"
      # drop_pct 0.72 -> "72%"
      assert email.html_body =~ "72%"
      assert is_binary(email.text_body) and email.text_body != ""
    end
  end
end
