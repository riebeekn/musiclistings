defmodule MusicListings.Mailer do
  use Swoosh.Mailer, otp_app: :music_listings
  alias Swoosh.Email

  def new(sender_name, sender_email, subject, message) do
    {:ok,
     Email.new()
     |> Email.to(Application.get_env(:music_listings, :admin_email))
     |> Email.from({sender_name, sender_email})
     |> Email.subject(subject)
     |> Email.text_body(message)}
  end
end
