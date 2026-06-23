defmodule MusicListings.Repo.Migrations.AddDateTitleIndexToEvents do
  use Ecto.Migration

  def change do
    # Supports the main events listing query, which filters on date >= ? over
    # non-deleted events and sorts by date then title with pagination. The
    # composite (date, title) order matches the sort exactly, letting Postgres
    # do an ordered range scan and satisfy the LIMIT without a separate sort.
    create index(:events, [:date, :title], where: "deleted_at IS NULL")
  end
end
