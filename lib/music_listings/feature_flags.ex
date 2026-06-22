defmodule MusicListings.FeatureFlags do
  @moduledoc """
  Context module for managing simple global boolean feature flags via FunWithFlags.
  """
  alias MusicListings.Accounts.User

  @type feature_flag :: %{name: atom(), enabled?: boolean()}

  @doc """
  Lists all persisted feature flags along with their current enabled state.
  """
  @spec list_feature_flags(User | nil) :: {:ok, list(feature_flag())} | {:error, :not_allowed}
  def list_feature_flags(%User{role: :admin}) do
    {:ok, names} = FunWithFlags.all_flag_names()

    flags =
      names
      |> Enum.sort()
      |> Enum.map(&%{name: &1, enabled?: FunWithFlags.enabled?(&1)})

    {:ok, flags}
  end

  def list_feature_flags(_user), do: {:error, :not_allowed}

  @doc """
  Enables or disables a feature flag globally.
  """
  @spec set_feature_flag(User | nil, atom(), boolean()) ::
          {:ok, boolean()} | {:error, :not_allowed}
  def set_feature_flag(%User{role: :admin}, flag_name, true) when is_atom(flag_name) do
    FunWithFlags.enable(flag_name)
  end

  def set_feature_flag(%User{role: :admin}, flag_name, false) when is_atom(flag_name) do
    FunWithFlags.disable(flag_name)
  end

  def set_feature_flag(_user, _flag_name, _enabled?), do: {:error, :not_allowed}
end
