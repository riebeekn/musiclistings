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

      def h1(var!(assigns)) do
        ~H"""
        <mj-text align="center" font-size="24px" font-weight="bold" padding-bottom="16px">
          {render_slot(@inner_block)}
        </mj-text>
        """
      end

      def h2(var!(assigns)) do
        ~H"""
        <mj-text align="left" font-size="18px" font-weight="bold" padding-top="5px">
          {render_slot(@inner_block)}
        </mj-text>
        """
      end

      def text(var!(assigns)) do
        ~H"""
        <mj-text align="left" font-size="14px" padding-top="2px">
          {render_slot(@inner_block)}
        </mj-text>
        """
      end

      def table(var!(assigns)) do
        ~H"""
        <mj-table>
          <thead>
            <tr style="border-bottom:1px solid #ecedee;text-align:left;padding:15px 0;">
              <%= for col <- @col do %>
                <th style="padding: 0 15px 0 0;">
                  {col.label}
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= for row <- @rows do %>
              <tr>
                <%= for col <- @col do %>
                  <td>{render_slot(col, row)}</td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
          <%= if @include_footer? do %>
            <tfoot>
              <tr style="border-top:1px solid #ecedee;text-align:left;padding:15px 0;">
                <%= for fcol <- @footer_col do %>
                  <td>
                    {render_slot(fcol)}
                  </td>
                <% end %>
              </tr>
            </tfoot>
          <% end %>
        </mj-table>
        """
      end

      defp layout(var!(assigns)) do
        ~H"""
        <mjml>
          <mj-body>
            <!-- main content -->
            <mj-section background-color="#FFFFFF" padding-bottom="20px" padding-top="20px">
              <mj-column vertical-align="top" width="100%">
                {@inner_content}
              </mj-column>
            </mj-section>
          </mj-body>
        </mjml>
        """
      end
    end
  end
end
