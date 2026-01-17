[
  {"lib/music_listings.ex", :invalid_contract},
  # Ecto.Multi uses MapSet internally, which is opaque in newer Elixir/OTP versions
  # These are false positives - the code is correct
  {"lib/music_listings/accounts.ex", :call_without_opaque}
]
