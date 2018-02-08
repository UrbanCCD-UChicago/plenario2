defmodule Plenario.Repo.Migrations.CreateAdminUserNotes do
  use Ecto.Migration

  def change do
    create table(:admin_user_notes) do
      add :message, :text
      add :should_email, :boolean, default: false
      add :acknowledged, :boolean, default: false

      add :admin_id, references(:users), null: false
      add :user_id, references(:users), null: false

      add :meta_id, references(:metas), null: true, default: nil
      add :etl_job_id, references(:etl_jobs), null: true, default: nil
      add :export_job_id, references(:export_jobs), null: true, default: nil

      timestamps(type: :timestamptz)
    end
  end
end
