defmodule MusicListingsWeb.CustomComponentsTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias MusicListingsWeb.CustomComponents

  describe "pager/1" do
    test "links to the neighbouring pages" do
      html =
        render_component(&CustomComponents.pager/1,
          current_page: 2,
          total_pages: 3,
          path: "/events"
        )

      assert html =~ "/events?page=1"
      assert html =~ "/events?page=3"
    end

    test "omits the prev link on the first page and the next link on the last" do
      first =
        render_component(&CustomComponents.pager/1,
          current_page: 1,
          total_pages: 2,
          path: "/events"
        )

      refute first =~ "Prev page"
      assert first =~ "Next page"

      last =
        render_component(&CustomComponents.pager/1,
          current_page: 2,
          total_pages: 2,
          path: "/events"
        )

      assert last =~ "Prev page"
      refute last =~ "Next page"
    end
  end
end
