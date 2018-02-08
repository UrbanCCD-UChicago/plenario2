defmodule Plenario.Repo.Migrations.CreateExportJobs do
  use Ecto.Migration

  def change do
    create table(:export_jobs) do
      add :meta_id, references(:metas), null: false
      add :user_id, references(:users), null: false

      add :query, :text, null: false
      add :include_diffs, :boolean, default: false
      add :export_path, :text, null: false
      add :export_ttl, :timestamptz, null: false
      add :diffs_path, :text, default: nil

      timestamps(type: :timestamptz)
    end

  end
end
