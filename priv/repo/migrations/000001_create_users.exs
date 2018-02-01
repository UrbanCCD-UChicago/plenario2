defmodule Plenario.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :text, null: false
      add :email, :text, null: false
      add :password_hash, :text, null: false

      add :bio, :text, default: nil

      add :is_active, :boolean, default: true
      add :is_admin, :boolean, default: false

      timestamps(type: :timestamptz)
    end

    create unique_index(:users, [:email])
  end
end
