defmodule MusicListingsWeb.FeatureFlagLiveTest do
  use MusicListingsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "index - when not logged in" do
    test "redirects to log in when attempting to access page", %{conn: conn} do
      assert {:error, {:redirect, redirect_map}} = live(conn, ~p"/feature_flags")

      assert redirect_map.to == "/users/log_in"
    end
  end

  describe "index - logged in" do
    setup :register_and_log_in_user

    setup do
      FunWithFlags.disable(:test_feature_flag)
      :ok
    end

    test "displays persisted feature flags", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/feature_flags")

      assert has_element?(view, "#flag-test_feature_flag")
    end

    test "shows a toggle reflecting the current state", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/feature_flags")

      assert has_element?(
               view,
               "#flag-test_feature_flag [phx-click=\"toggle-flag\"][phx-value-enabled=\"false\"]"
             )
    end

    test "toggling a flag on enables it", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/feature_flags")

      view
      |> element("#flag-test_feature_flag button")
      |> render_click()

      assert FunWithFlags.enabled?(:test_feature_flag)

      assert has_element?(
               view,
               "#flag-test_feature_flag [phx-click=\"toggle-flag\"][phx-value-enabled=\"true\"]"
             )
    end

    test "toggling a flag off disables it", %{conn: conn} do
      FunWithFlags.enable(:test_feature_flag)

      {:ok, view, _html} = live(conn, ~p"/feature_flags")

      view
      |> element("#flag-test_feature_flag button")
      |> render_click()

      refute FunWithFlags.enabled?(:test_feature_flag)
    end
  end
end
