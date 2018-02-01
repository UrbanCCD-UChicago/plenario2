defmodule Plenario.Repo.Migrations.CreateDataSetFields do
  use Ecto.Migration

  def change do
    create table(:data_set_fields) do
      # column info
      add :name, :text, null: false
      add :type, :text, null: false
      add :opts, :text, null: false, default: "default null"

      # belongs to a meta entry
      add :meta_id, references(:metas)
    end

    create unique_index(:data_set_fields, [:meta_id, :name])
  end
end
