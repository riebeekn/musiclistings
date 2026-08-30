defmodule MusicListings.Repo.Migrations.CreateEventFlags do
  use Ecto.Migration

  def change do
    create table(:event_flags) do
      add :event_id, references(:events), null: false
      add :related_event_id, references(:events)
      add :type, :string, null: false
      add :reason, :string, null: false
      add :dismissed_at, :utc_datetime

      timestamps()
    end

    create index(:event_flags, [:event_id])
    create index(:event_flags, [:related_event_id])

    # Two partial indexes rather than one over the three columns: NULL is
    # distinct from NULL in a unique index, so a plain index would let a
    # non-pair flag be inserted over and over.  NULLS NOT DISTINCT would also
    # do it, but only on Postgres 15+.
    create unique_index(:event_flags, [:event_id, :type], where: "related_event_id IS NULL")

    create unique_index(:event_flags, [:event_id, :type, :related_event_id],
             where: "related_event_id IS NOT NULL"
           )

    # The review queue only ever reads open flags.
    create index(:event_flags, [:dismissed_at], where: "dismissed_at IS NULL")
  end
end
