defmodule Plenario.Repo.Migrations.AddStateFieldsToExportJob do
  use Ecto.Migration

  def change do
    alter table(:export_jobs) do
      add :state, :text, default: "new"
      add :error_message, :text, default: nil
    end
  end
end
