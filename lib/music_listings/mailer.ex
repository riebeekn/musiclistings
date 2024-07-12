defmodule MusicListings.Mailer do
  use Swoosh.Mailer, otp_app: :music_listings

  defmacro __using__(_opts) do
    quote do
      import Phoenix.Component
      import Swoosh.Email

      alias Phoenix.HTML.Safe

      @spec body(Swoosh.Email.t(), Phoenix.LiveView.Rendered.t()) :: Swoosh.Email.t()
      def body(email, mjml) do
        mjml =
          %{inner_content: mjml}
          |> layout()
          |> Safe.to_iodata()
          |> IO.chardata_to_string()

        mjml_minus_heex_debug_annotations = Regex.replace(~r/<!--.*?-->/s, mjml, "")

        {:ok, html_body} = Mjml.to_html(mjml_minus_heex_debug_annotations)

        text_body = html_body |> Premailex.to_text()

        email
        |> html_body(html_body)
        |> text_body(text_body)
      end

      def header(var!(assigns)) do
        ~H"""
        <mj-text align="center" font-size="24px" font-weight="bold" padding-bottom="16px">
          <%= render_slot(@inner_block) %>
        </mj-text>
        """
      end

      def text(var!(assigns)) do
        ~H"""
        <mj-text align="left" font-size="16px" padding-top="5px">
          <%= render_slot(@inner_block) %>
        </mj-text>
        """
      end

      defp layout(var!(assigns)) do
        ~H"""
        <mjml>
          <mj-body>
            <!-- main content -->
            <mj-section background-color="#FFFFFF" padding-bottom="20px" padding-top="20px">
              <mj-column vertical-align="top" width="100%">
                <%= @inner_content %>
              </mj-column>
            </mj-section>
          </mj-body>
        </mjml>
        """
      end
    end
  end
end
