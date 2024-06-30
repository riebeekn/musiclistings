defmodule MusicListingsWeb.ErrorJSONTest do
  use MusicListingsWeb.ConnCase, async: true

  test "renders 404" do
    assert MusicListingsWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert MusicListingsWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
