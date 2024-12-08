defmodule MusicListings.Emails.ContactUs do
  @moduledoc """
  Email that gets sent from the contact us form
  """
  use MusicListings.Mailer

  def new_email(%{name: sender_name, email: sender_email, subject: subject, message: message}) do
    new()
    |> to_site_admin()
    |> from({sender_name, sender_email})
    |> subject(subject)
    |> text_body(message)
  end

  def preview do
    %{
      name: "Bob Mintzer",
      email: "bob@example.com",
      subject: "The message subject",
      message: "The message body"
    }
    |> new_email()
  end

  def preview_details do
    [
      title: "Contact Us",
      description: "Sent when a message is submitted via the contact us form",
      tags: [category: "Admin"]
    ]
  end
end
