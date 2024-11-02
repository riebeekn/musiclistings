defmodule MusicListingsWeb.ContactLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Swoosh.TestAssertions

  describe "new" do
    test "saves submitted event with valid parameters", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/contact")
      assert has_element?(view, "h1", "Get in touch")

      {:ok, _view, html} =
        view
        |> form("#contact-form", %{
          "contact" => %{
            "name" => "Bob Mintzer",
            "email" => "bob@example.com",
            "subject" => "Hi there!",
            "message" => "Hello, I have a question about..."
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/events")

      assert html =~ "Thank you for contacting us"

      assert_email_sent(
        from: {"Bob Mintzer", "bob@example.com"},
        subject: "Hi there!",
        text_body: "Hello, I have a question about..."
      )
    end

    test "displays errors with invalid attributes", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/contact")

      view
      |> form("#contact-form", %{"contact" => %{}})

      assert view
             |> form("#contact-form", %{"contact" => %{}})
             |> render_submit() =~ "can&#39;t be blank"
    end
  end
end
