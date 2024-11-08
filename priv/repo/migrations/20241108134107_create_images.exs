defmodule Gregslist.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :itemId, :integer
      add :dataUrl, :string
      timestamps(type: :utc_datetime)
    end
  end
end
