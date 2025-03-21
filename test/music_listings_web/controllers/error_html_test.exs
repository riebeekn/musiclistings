defmodule MusicListingsWeb.ErrorHTMLTest do
  use MusicListingsWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(MusicListingsWeb.ErrorHTML, "404", "html", []) =~
             "It seems like this page doesn't exist"
  end

  test "renders 500.html" do
    assert render_to_string(MusicListingsWeb.ErrorHTML, "500", "html", []) ==
             "Internal Server Error"
  end
end
