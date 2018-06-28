defmodule Plenario.Repo.Migrations.EtlByeBye do
  use Ecto.Migration

  def change do
    drop table(:data_set_diffs)

    drop table(:unique_constraints)

    alter table(:export_jobs) do
      remove :include_diffs
      remove :diffs_path
    end
  end
end
