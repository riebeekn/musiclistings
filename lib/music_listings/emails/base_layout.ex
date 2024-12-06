defmodule MusicListings.Emails.BaseLayout do
  @moduledoc """
  Base layout for emails
  """
  use MjmlEEx.Layout, mjml_layout: "templates/base_layout.mjml.eex"
end
