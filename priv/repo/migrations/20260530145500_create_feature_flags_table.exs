defmodule MusicListings.Repo.Migrations.CreateFeatureFlagsTable do
  use Ecto.Migration

  # Table used by FunWithFlags' Ecto persistence adapter. Mirrors the migration
  # shipped with the library (deps/fun_with_flags/priv/ecto_repo/migrations/) but
  # renamed to `feature_flags` via the :ecto_table_name config in config/config.exs.

  def up do
    create table(:feature_flags) do
      add :flag_name, :string, null: false
      add :gate_type, :string, null: false
      add :target, :string, null: false
      add :enabled, :boolean, null: false
    end

    create index(
             :feature_flags,
             [:flag_name, :gate_type, :target],
             unique: true,
             name: "feature_flags_flag_name_gate_target_idx"
           )
  end

  def down do
    drop table(:feature_flags)
  end
end
