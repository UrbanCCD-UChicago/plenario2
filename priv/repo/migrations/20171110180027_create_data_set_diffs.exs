defmodule Plenario2.Repo.Migrations.CreateDataSetDiffs do
  use Ecto.Migration

  def change do
    create table(:data_set_diffs) do
      # `row_uniques` is a key-value of the col names and values for the unique constraint of that row
      add :column,            :text
      add :original,          :text
      add :update,            :text
      add :changed_on,        :timestamptz
      add :constraint_values, :json

      # belongs to a meta entry and happens during an etl job
      add :meta_id,               references(:metas)
      add :data_set_constraint_id,  references(:data_set_constraints)
      add :etl_job_id,             references(:etl_jobs)
    end
  end
end
