defmodule Plenario.Repo.Migrations.CreateEtlJobs do
  use Ecto.Migration

  def change do
    create table(:etl_jobs) do
      add :state,         :text
      add :started_on,    :timestamptz, default: nil
      add :completed_on,  :timestamptz, default: nil

      # belongs to a meta entry
      add :meta_id, references(:metas)
    end
  end
end
