defmodule MusicListings.Emails.Components do
  @moduledoc """
  Shared MJML building blocks for the transactional emails, styled to match the
  site's "After Dark" theme (see the palette reference in `MusicListings.Mailer`).

  These are imported into every email module via `use MusicListings.Mailer`, so
  they can be called as `<.h1>`, `<.table>`, `<.stat_band>`, etc.
  """
  use Phoenix.Component

  @doc "Outer MJML shell: branded masthead, content card and footer."
  attr :inner_content, :any, required: true

  def layout(assigns) do
    ~H"""
    <mjml>
      <mj-head>
        <mj-font
          name="Big Shoulders Display"
          href="https://fonts.googleapis.com/css2?family=Big+Shoulders+Display:wght@600;700;800&display=swap"
        />
        <mj-font
          name="Hanken Grotesk"
          href="https://fonts.googleapis.com/css2?family=Hanken+Grotesk:wght@400;600;700&display=swap"
        />
        <mj-font
          name="Space Mono"
          href="https://fonts.googleapis.com/css2?family=Space+Mono&display=swap"
        />
        <mj-attributes>
          <mj-all font-family="'Hanken Grotesk', Helvetica, Arial, sans-serif" />
          <mj-text color="#ece9e0" font-size="14px" line-height="1.55" />
        </mj-attributes>
      </mj-head>
      <mj-body background-color="#0b0b0c" width="640px">
        <!-- masthead -->
        <mj-section background-color="#0b0b0c" padding="28px 24px 0 24px">
          <mj-column>
            <mj-text
              align="left"
              font-family="'Big Shoulders Display', 'Hanken Grotesk', Helvetica, Arial, sans-serif"
              font-size="22px"
              font-weight="800"
              letter-spacing="3px"
              color="#d8ff3e"
              padding="0"
            >
              TORONTO MUSIC LISTINGS
            </mj-text>
            <mj-divider border-width="1px" border-color="#2b2b27" padding="14px 0 0 0" />
          </mj-column>
        </mj-section>
        <!-- content card -->
        <mj-section
          background-color="#141415"
          border-top="3px solid #d8ff3e"
          border-radius="0 0 10px 10px"
          padding="26px 24px"
        >
          <mj-column vertical-align="top" width="100%">
            {@inner_content}
          </mj-column>
        </mj-section>
        <!-- footer -->
        <mj-section background-color="#0b0b0c" padding="18px 24px 28px 24px">
          <mj-column>
            <mj-text align="center" color="#a8a49a" font-size="12px" line-height="1.6">
              Sent by Toronto Music Listings ·
              <a href="https://torontomusiclistings.com" style="color:#d8ff3e;text-decoration:none;">torontomusiclistings.com</a>
            </mj-text>
          </mj-column>
        </mj-section>
      </mj-body>
    </mjml>
    """
  end

  @doc "Large display heading (paper on ink)."
  slot :inner_block, required: true

  def h1(assigns) do
    ~H"""
    <mj-text
      align="left"
      font-family="'Big Shoulders Display', 'Hanken Grotesk', Helvetica, Arial, sans-serif"
      font-size="30px"
      font-weight="800"
      letter-spacing="0.5px"
      color="#ece9e0"
      padding-bottom="4px"
    >
      {render_slot(@inner_block)}
    </mj-text>
    """
  end

  @doc "Section sub-heading."
  slot :inner_block, required: true

  def h2(assigns) do
    ~H"""
    <mj-text
      align="left"
      font-family="'Big Shoulders Display', 'Hanken Grotesk', Helvetica, Arial, sans-serif"
      font-size="20px"
      font-weight="700"
      letter-spacing="0.5px"
      color="#ece9e0"
      padding-top="20px"
      padding-bottom="4px"
    >
      {render_slot(@inner_block)}
    </mj-text>
    """
  end

  @doc "Body copy."
  slot :inner_block, required: true

  def text(assigns) do
    ~H"""
    <mj-text align="left" font-size="14px" color="#ece9e0" line-height="1.55" padding-top="2px">
      {render_slot(@inner_block)}
    </mj-text>
    """
  end

  @doc "Muted, secondary line of text (paper-dim)."
  slot :inner_block, required: true

  def muted(assigns) do
    ~H"""
    <mj-text align="left" font-size="13px" color="#a8a49a" line-height="1.55" padding-top="2px">
      {render_slot(@inner_block)}
    </mj-text>
    """
  end

  @doc """
  A horizontal row of big-number stats. Each `:stat` slot renders its value as the
  block content and carries a `label` and optional `accent` ("spotlight" | "ember",
  anything else renders in paper).
  """
  slot :stat, required: true do
    attr :label, :string, required: true
    attr :accent, :string
  end

  def stat_band(assigns) do
    ~H"""
    <mj-text padding="6px 0 10px 0">
      <table role="presentation" width="100%" style="border-collapse:collapse;text-align:center;">
        <tr>
          <%= for stat <- @stat do %>
            <td style="padding:6px 4px;vertical-align:top;width:33%;">
              <div style={"font-family:'Big Shoulders Display','Hanken Grotesk',Helvetica,Arial,sans-serif;font-size:44px;font-weight:800;line-height:1;color:#{stat_accent(stat[:accent])};"}>
                {render_slot(stat)}
              </div>
              <div style="font-size:11px;font-weight:700;letter-spacing:2px;text-transform:uppercase;color:#a8a49a;padding-top:8px;">
                {stat.label}
              </div>
            </td>
          <% end %>
        </tr>
      </table>
    </mj-text>
    """
  end

  @doc """
  Small inline pill, e.g. `<.badge>NEW</.badge>`. Spotlight on ink by default;
  pass `tone="ember"` for an alert pill.
  """
  attr :tone, :string, default: "spotlight"
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span style={"display:inline-block;background-color:#{badge_bg(@tone)};color:#0b0b0c;font-size:10px;font-weight:700;letter-spacing:1px;text-transform:uppercase;padding:2px 7px;border-radius:9999px;"}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  @doc """
  A dark-themed data table. `:col` slots define columns (each with a `label`); the
  optional footer row is built from `:footer_col` slots when `include_footer?` is true.
  """
  attr :rows, :list, required: true
  attr :include_footer?, :boolean, default: false

  slot :col, required: true do
    attr :label, :string, required: true
  end

  slot :footer_col

  def table(assigns) do
    ~H"""
    <mj-table color="#ece9e0" font-size="13px" line-height="1.4" padding="4px 0">
      <thead>
        <tr style="border-bottom:1px solid #2b2b27;text-align:left;">
          <%= for col <- @col do %>
            <th style="padding:6px 14px 8px 0;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;color:#a8a49a;">
              {col.label}
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for row <- @rows do %>
          <tr style="border-bottom:1px solid #1c1c1d;">
            <%= for col <- @col do %>
              <td style="padding:9px 14px 9px 0;">{render_slot(col, row)}</td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
      <%= if @include_footer? do %>
        <tfoot>
          <tr style="border-top:2px solid #2b2b27;text-align:left;">
            <%= for fcol <- @footer_col do %>
              <td style="padding:10px 14px 4px 0;font-weight:700;color:#ece9e0;">
                {render_slot(fcol)}
              </td>
            <% end %>
          </tr>
        </tfoot>
      <% end %>
    </mj-table>
    """
  end

  @doc """
  A label/value list. Each `:item` slot carries a `label` and renders its value as
  the block content — used for the key facts of a submission or message.
  """
  slot :item, required: true do
    attr :label, :string, required: true
  end

  def details(assigns) do
    ~H"""
    <mj-text padding="4px 0">
      <table role="presentation" width="100%" style="border-collapse:collapse;">
        <%= for item <- @item do %>
          <tr>
            <td style="padding:9px 16px 9px 0;border-bottom:1px solid #1c1c1d;color:#a8a49a;font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;white-space:nowrap;vertical-align:top;">
              {item.label}
            </td>
            <td style="padding:9px 0;border-bottom:1px solid #1c1c1d;color:#ece9e0;font-size:14px;line-height:1.5;vertical-align:top;">
              {render_slot(item)}
            </td>
          </tr>
        <% end %>
      </table>
    </mj-text>
    """
  end

  @doc "A spotlight call-to-action button."
  attr :href, :string, required: true
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <mj-button
      href={@href}
      background-color="#d8ff3e"
      color="#0b0b0c"
      font-weight="700"
      font-size="14px"
      border-radius="8px"
      align="left"
      inner-padding="12px 22px"
      padding="18px 0 4px 0"
    >
      {render_slot(@inner_block)}
    </mj-button>
    """
  end

  @doc """
  A quoted block (left spotlight rule on an ink-3 card) for free-text content such
  as a contact message. Preserves the author's line breaks.
  """
  slot :inner_block, required: true

  def quote_block(assigns) do
    ~H"""
    <mj-text padding="6px 0">
      <div style="border-left:3px solid #d8ff3e;background-color:#1c1c1d;border-radius:6px;padding:14px 16px;color:#ece9e0;font-size:14px;line-height:1.6;white-space:pre-wrap;">
        {render_slot(@inner_block)}
      </div>
    </mj-text>
    """
  end

  defp stat_accent("spotlight"), do: "#d8ff3e"
  defp stat_accent("ember"), do: "#ff5a36"
  defp stat_accent(_other), do: "#ece9e0"

  defp badge_bg("ember"), do: "#ff5a36"
  defp badge_bg(_other), do: "#d8ff3e"
end
