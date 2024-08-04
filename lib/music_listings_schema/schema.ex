defmodule MusicListingsSchema.Schema do
  @moduledoc """
  Base schema file
  """
  defmacro __using__(_env) do
    quote do
      use Ecto.Schema

      @timestamps_opts [
        type: :utc_datetime_usec,
        autogenerate: {MusicListingsUtilities.DateHelpers, :now, []}
      ]
    end
  end
end
