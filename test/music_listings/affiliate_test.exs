defmodule MusicListings.AffiliateTest do
  use ExUnit.Case, async: true

  alias MusicListings.Affiliate

  @base_url "https://ticketmaster.evyy.net/c/7166785/264167/4272"

  describe "maybe_wrap_affiliate_link/1" do
    test "returns nil for nil URL" do
      assert Affiliate.maybe_wrap_affiliate_link(nil) == nil
    end

    test "wraps ticketmaster.ca URL" do
      url = "https://www.ticketmaster.ca/event/abc123"

      assert Affiliate.maybe_wrap_affiliate_link(url) ==
               "#{@base_url}?u=#{URI.encode_www_form(url)}"
    end

    test "wraps ticketmaster.com URL" do
      url = "https://www.ticketmaster.com/event/abc123"

      assert Affiliate.maybe_wrap_affiliate_link(url) ==
               "#{@base_url}?u=#{URI.encode_www_form(url)}"
    end

    test "wraps ticketweb.ca URL" do
      url = "https://www.ticketweb.ca/event/some-show/14053944?pl=CODA"

      assert Affiliate.maybe_wrap_affiliate_link(url) ==
               "#{@base_url}?u=#{URI.encode_www_form(url)}"
    end

    test "wraps universe.com URL" do
      url = "https://www.universe.com/events/some-event"

      assert Affiliate.maybe_wrap_affiliate_link(url) ==
               "#{@base_url}?u=#{URI.encode_www_form(url)}"
    end

    test "wraps universe.ca URL" do
      url = "https://www.universe.ca/events/some-event"

      assert Affiliate.maybe_wrap_affiliate_link(url) ==
               "#{@base_url}?u=#{URI.encode_www_form(url)}"
    end

    test "returns unknown domain URL unchanged" do
      url = "https://www.somevenue.com/shows"
      assert Affiliate.maybe_wrap_affiliate_link(url) == url
    end

    test "returns eventbrite URL unchanged" do
      url = "https://www.eventbrite.com/e/my-event-123"
      assert Affiliate.maybe_wrap_affiliate_link(url) == url
    end

    test "returns malformed URL unchanged" do
      assert Affiliate.maybe_wrap_affiliate_link("not-a-url") == "not-a-url"
    end

    test "correctly encodes URL with existing query params" do
      url = "https://www.ticketmaster.ca/event/abc123?lang=en"
      encoded = URI.encode_www_form(url)
      assert Affiliate.maybe_wrap_affiliate_link(url) == "#{@base_url}?u=#{encoded}"
    end
  end
end
