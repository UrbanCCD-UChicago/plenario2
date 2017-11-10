defmodule Plenario2.Repo.Migrations.CreateExportJobs do
  use Ecto.Migration

  def change do
    create table(:export_jobs) do
      # user and meta relationshipts
      add :meta_id, references(:metas), null: false
      add :user_id, references(:users), null: false

      # query info
      add :query,         :text,    null: false
      add :include_diffs, :boolean, default: false

      # export info
      add :export_path, :text,        null: false
      add :export_ttl,  :timestamptz, null: false
      add :diffs_path,  :text

      # create/update timestamps
      timestamps(type: :timestamptz)
    end

  end
end
