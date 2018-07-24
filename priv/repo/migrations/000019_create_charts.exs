defmodule Plenario.Repo.Migrations.CreateCharts do
  use Ecto.Migration

  def change do
    create table(:charts) do
      add :meta_id, references(:metas, on_delete: :delete_all)
      add :title, :text
      add :type, :text
      add :timestamp_field, :text
      add :point_field, :text
      add :group_by_field, :text
    end

    create table(:chart_datasets) do
      add :chart_id, references(:charts, on_delete: :delete_all)
      add :label, :text
      add :field_name, :text
      add :func, :text
      add :color, :text
      add :fill?, :boolean
    end
  end
end
