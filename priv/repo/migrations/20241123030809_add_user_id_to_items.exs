defmodule Gregslist.Repo.Migrations.AddUserIdToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :user_id, references(:users, on_delete: :nothing)
    end

    create index(:items, [:user_id])
  end
end
