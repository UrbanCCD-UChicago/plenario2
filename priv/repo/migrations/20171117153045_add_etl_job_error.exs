defmodule Plenario.Repo.Migrations.AddEtlJobError do
  use Ecto.Migration

  def change do
    alter table(:etl_jobs) do
      add :error_message, :text, default: nil
    end
  end
end
