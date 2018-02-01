defmodule Plenario.Repo.Migrations.CreateDataSetDiffs do
  use Ecto.Migration

  def change do
    create table(:data_set_diffs) do
      add :column, :text
      add :original, :text
      add :update, :text
      add :changed_on, :timestamptz
      add :constraint_values, :json

      add :meta_id, references(:metas), null: false
      add :unique_constraint_id, references(:unique_constrainsts), null: false
      add :etl_job_id, references(:etl_jobs), null: false

      timestamps(type: :timestamptz)
    end
  end
end
