defmodule MusicListings.Affiliate do
  @moduledoc """
  Wraps outbound ticket URLs in an Impact.com affiliate redirect
  for Ticketmaster-family domains (Ticketmaster, TicketWeb, Universe).
  """

  @base_url "https://ticketmaster.evyy.net/c/7166785/264167/4272"
  @supported_domains ["ticketmaster", "ticketweb", "universe"]

  @doc """
  Wraps a ticket URL in an Impact.com affiliate redirect if the domain
  is a supported Ticketmaster-family platform.

  Returns the URL unchanged if the domain doesn't match.
  Returns nil if given nil.
  """
  @spec maybe_wrap_affiliate_link(String.t() | nil) :: String.t() | nil
  def maybe_wrap_affiliate_link(nil), do: nil

  def maybe_wrap_affiliate_link(url) do
    uri = URI.parse(url)

    if supported_domain?(uri.host) do
      "#{@base_url}?u=#{URI.encode_www_form(url)}"
    else
      url
    end
  end

  defp supported_domain?(nil), do: false

  defp supported_domain?(host) do
    host
    |> String.downcase()
    |> String.split(".")
    |> Enum.any?(&(&1 in @supported_domains))
  end
end
