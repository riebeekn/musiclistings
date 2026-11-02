defmodule MusicListings.Repo.Migrations.DropTicketnetworkUrlFromEvents do
  use Ecto.Migration

  # The TicketNetwork resale links were the only reader of this column. The schema
  # field was removed a deploy earlier, so no running instance selects it any more
  # and it is safe to drop (migrations run on boot, while the old instance still serves).

  def change do
    alter table(:events) do
      remove :ticketnetwork_url, :string, size: 2048
    end
  end
end
