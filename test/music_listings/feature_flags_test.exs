defmodule MusicListings.FeatureFlagsTest do
  use MusicListings.DataCase, async: true

  alias MusicListings.Accounts.User
  alias MusicListings.FeatureFlags

  setup do
    FunWithFlags.disable(:test_feature_flag)
    :ok
  end

  describe "list_feature_flags/1" do
    test "returns an error for non-admins" do
      assert {:error, :not_allowed} == FeatureFlags.list_feature_flags(nil)

      assert {:error, :not_allowed} ==
               FeatureFlags.list_feature_flags(%User{role: :regular_user})
    end

    test "returns persisted flags with their state for admins" do
      assert {:ok, flags} = FeatureFlags.list_feature_flags(%User{role: :admin})
      assert %{name: :test_feature_flag, enabled?: false} in flags
    end
  end

  describe "set_feature_flag/3" do
    test "returns an error for non-admins" do
      assert {:error, :not_allowed} ==
               FeatureFlags.set_feature_flag(nil, :test_feature_flag, true)

      assert {:error, :not_allowed} ==
               FeatureFlags.set_feature_flag(%User{role: :regular_user}, :test_feature_flag, true)

      refute FunWithFlags.enabled?(:test_feature_flag)
    end

    test "enables a flag for admins" do
      assert {:ok, true} =
               FeatureFlags.set_feature_flag(%User{role: :admin}, :test_feature_flag, true)

      assert FunWithFlags.enabled?(:test_feature_flag)
    end

    test "disables a flag for admins" do
      FunWithFlags.enable(:test_feature_flag)

      assert {:ok, false} =
               FeatureFlags.set_feature_flag(%User{role: :admin}, :test_feature_flag, false)

      refute FunWithFlags.enabled?(:test_feature_flag)
    end
  end
end
