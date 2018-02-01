defmodule Plenario.Repo.Migrations.CreateEtlJobs do
  use Ecto.Migration

  def change do
    create table(:etl_jobs) do
      add :state, :text
      add :started_on, :timestamptz, default: nil
      add :completed_on, :timestamptz, default: nil
      add :error_message, :text, default: nil

      add :meta_id, references(:metas), null: false

      timestamps(type: :timestamptz)
    end
  end
end
