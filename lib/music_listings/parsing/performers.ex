defmodule MusicListings.Parsing.Performers do
  @moduledoc """
  Struct and functions to represent/parse event performers
  """
  @type t :: %__MODULE__{
          headliner: String.t(),
          openers: list(String.t())
        }
  defstruct [:headliner, :openers]

  def new([]), do: %__MODULE__{headliner: nil, openers: []}

  def new([headliner | openers]), do: %__MODULE__{headliner: headliner, openers: openers}
end
