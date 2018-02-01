defmodule Plenario.Repo.Migrations.CreateAdminUserNoteTable do
  use Ecto.Migration

  def change do
    create table(:admin_user_notes) do
      add :note, :text
      add :should_email, :boolean, default: false
      add :acknowledged, :boolean, default: false

      timestamps(type: :timestamptz)

      add :admin_id, references(:users)
      add :user_id, references(:users)
      add :meta_id, references(:metas), null: true, default: nil
      add :etl_job_id, references(:etl_jobs), null: true, default: nil
      add :export_job_id, references(:export_jobs), null: true, default: nil
    end
  end
end
