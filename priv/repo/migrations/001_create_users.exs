defmodule Plenario.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :text
      add :email, :text
      add :password_hash, :text
      add :bio, :text, default: nil
      add :is_admin?, :boolean, default: false
    end

    create unique_index(:users, :username)

    create unique_index(:users, :email)

    create index(:users, :is_admin?)
  end
end
