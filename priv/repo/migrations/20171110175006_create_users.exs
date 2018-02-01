defmodule Plenario.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      # typical user stuff
      add :name,            :text, null: false
      add :organization,    :text, default: nil
      add :org_role,        :text, default: nil
      add :hashed_password, :text, null: false
      add :email_address,   :text, null: false

      # status flags
      add :is_active,   :boolean, default: true
      add :is_trusted,  :boolean, default: false
      add :is_admin,    :boolean, default: false

      # create/update timestamps
      timestamps(type: :timestamptz)
    end

    create unique_index(:users, [:email_address])
  end
end
