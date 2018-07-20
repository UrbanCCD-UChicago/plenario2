defmodule Plenario.Repo.Migrations.DropEtlJobs do
  use Ecto.Migration

  def change do
    alter table(:admin_user_notes) do
      remove :etl_job_id
    end

    drop table(:etl_jobs)
  end
end
