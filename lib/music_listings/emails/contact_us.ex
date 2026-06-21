defmodule MusicListings.Emails.ContactUs do
  @moduledoc """
  Email that gets sent from the contact us form
  """
  use MusicListings.Mailer

  def new_email(%{name: sender_name, email: sender_email, subject: subject, message: message}) do
    assigns = %{
      name: sender_name,
      email: sender_email,
      subject: subject,
      message: message,
      reply_href: reply_href(sender_email, subject)
    }

    new()
    |> to_site_admin()
    |> from({sender_name, sender_email})
    |> reply_to({sender_name, sender_email})
    |> subject(subject)
    |> body(mjml(assigns))
  end

  defp mjml(assigns) do
    ~H"""
    <.h1>New Contact Message</.h1>
    <.muted>Sent via the contact form on torontomusiclistings.com</.muted>

    <.details>
      <:item label="From">{@name}</:item>
      <:item label="Email">
        <a href={"mailto:#{@email}"} style="color:#d8ff3e;text-decoration:none;">{@email}</a>
      </:item>
      <:item label="Subject">{@subject}</:item>
    </.details>

    <.h2>Message</.h2>
    <.quote_block>{@message}</.quote_block>

    <.button href={@reply_href}>Reply to {@name} →</.button>
    """
  end

  defp reply_href(email, subject) do
    "mailto:#{email}?subject=#{URI.encode("Re: " <> subject)}"
  end

  def preview do
    %{
      name: "Bob Mintzer",
      email: "bob@example.com",
      subject: "The message subject",
      message: "The message body.\n\nThanks,\nBob"
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
