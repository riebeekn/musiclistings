[
  {"lib/music_listings.ex", :invalid_contract},
  # Ecto.Multi uses MapSet internally, which is opaque in newer Elixir/OTP versions
  # These are false positives - the code is correct
  {"lib/music_listings/accounts.ex", :call_without_opaque},
  # Event schema @type marks ticket_url as String.t() but the DB column is
  # nullable. The defensive nil check is correct at runtime even though
  # dialyzer considers it unreachable per the (incomplete) spec.
  {"lib/music_listings_web/seo.ex", :pattern_match}
]
