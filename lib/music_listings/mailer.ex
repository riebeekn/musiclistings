defmodule MusicListings.Mailer do
  use Swoosh.Mailer, otp_app: :music_listings

  # Brand palette — mirrors the site's "After Dark" theme (assets/css/app.css @theme).
  # Kept here for reference; the hexes are used as literals throughout the MJML
  # components in `MusicListings.Emails.Components`.
  #
  #   ink            #0b0b0c   page background
  #   ink-2          #141415   content card background
  #   ink-3          #1c1c1d   subtle chip / code block background
  #   paper          #ece9e0   primary text
  #   paper-dim      #a8a49a   muted / secondary text
  #   spotlight      #d8ff3e   accent (NEW, wordmark, links)
  #   ember          #ff5a36   errors / alerts
  #   hairline       #2b2b27   borders / dividers

  defmacro __using__(_opts) do
    quote do
      import MusicListings.Emails.Components
      import Phoenix.Component
      import Swoosh.Email

      alias Phoenix.HTML.Safe

      @spec to_site_admin(Swoosh.Email.t()) :: Swoosh.Email.t()
      def to_site_admin(email) do
        to(email, Application.get_env(:music_listings, :admin_email))
      end

      @spec from_noreply(Swoosh.Email.t()) :: Swoosh.Email.t()
      def from_noreply(email) do
        from(email, {"Toronto Music Listings", "no-reply@torontomusiclistings.com"})
      end

      @spec body(Swoosh.Email.t(), Phoenix.LiveView.Rendered.t()) :: Swoosh.Email.t()
      def body(email, mjml) do
        rendered_mjml =
          %{inner_content: mjml}
          |> layout()
          |> Safe.to_iodata()
          |> IO.chardata_to_string()

        mjml_minus_heex_debug_annotations = Regex.replace(~r/<!--.*?-->/s, rendered_mjml, "")

        {:ok, html_body} = Mjml.to_html(mjml_minus_heex_debug_annotations)

        text_body = Premailex.to_text(html_body)

        email
        |> html_body(html_body)
        |> text_body(text_body)
      end

      @spec pluralize(integer(), String.t()) :: String.t()
      def pluralize(1, word), do: word
      def pluralize(_count, word), do: word <> "s"
    end
  end
end
