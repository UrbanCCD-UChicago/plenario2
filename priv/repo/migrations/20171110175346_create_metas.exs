defmodule Plenario.Repo.Migrations.CreateMetas do
  use Ecto.Migration

  def change do
    create table(:metas) do
      # id and ownership
      add :name,    :text,              null: false
      add :slug,    :text,              null: false
      add :user_id, references(:users), null: false

      # workflow
      add :state, :text, null: false

      # additional info
      add :description, :text, default: nil
      add :attribution, :text, default: nil

      # source info
      add :source_url,  :text, null: false
      add :source_type, :text, null: false

      # import milestones
      add :first_import,  :timestamptz, default: nil
      add :latest_import, :timestamptz, default: nil

      # refresh info
      add :refresh_rate,      :text,        default: nil
      add :refresh_interval,  :integer,     default: nil
      add :refresh_starts_on, :timestamptz, default: nil
      add :refresh_ends_on,   :timestamptz, default: nil

      # geo info
      add :srid, :integer, default: 4326
      add :bbox, :polygon, default: nil

      # time info
      add :timezone,  :text,      default: "UTC"
      add :timerange, :tstzrange, default: nil

      # create/update timestamps
      timestamps(type: :timestamptz)
    end

    create unique_index(:metas, [:name])
    create unique_index(:metas, [:slug])
    create unique_index(:metas, [:source_url])
  end
end
