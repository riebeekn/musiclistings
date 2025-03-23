{:ok, _type} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(MusicListings.Repo, :manual)
