defmodule MusicListings.Repo.Migrations.AddTicketnetworkUrlToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :ticketnetwork_url, :string, size: 2048
    end
  end
end
