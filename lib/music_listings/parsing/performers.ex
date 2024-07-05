defmodule MusicListings.Parsing.Performers do
  defstruct [:headliner, :openers]

  def new([]), do: %__MODULE__{headliner: "", openers: []}

  def new([headliner | openers]), do: %__MODULE__{headliner: headliner, openers: openers}
end
