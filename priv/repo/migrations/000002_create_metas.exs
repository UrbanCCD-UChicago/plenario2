defmodule Plenario.Repo.Migrations.CreateMetas do
  use Ecto.Migration

  def change do
    create table(:metas) do
      add :name, :text, null: false
      add :slug, :text, null: false
      add :table_name, :text, null: false
      add :user_id, references(:users), null: false

      add :state, :text, null: false

      add :description, :text, default: nil
      add :attribution, :text, default: nil

      add :source_url, :text, null: false
      add :source_type, :text, null: false

      add :refresh_rate, :text, default: nil
      add :refresh_interval, :integer, default: nil
      add :refresh_starts_on, :date, default: nil
      add :refresh_ends_on, :date, default: nil

      add :first_import, :timestamptz, default: nil
      add :latest_import, :timestamptz, default: nil
      add :next_import, :timestamptz, default: nil

      add :bbox, :geometry, default: nil
      add :time_range, :tstzrange, default: nil

      timestamps(type: :timestamptz)
    end

    create unique_index(:metas, [:name])
    create unique_index(:metas, [:slug])
    create unique_index(:metas, [:source_url])
  end
end
