defmodule Plenario.Repo.Migrations.CreateDataSetFields do
  use Ecto.Migration

  def change do
    create table(:data_set_fields) do
      add :name, :text, null: false
      add :type, :text, null: false

      add :meta_id, references(:metas, on_delete: :delete_all), null: false

      timestamps(type: :timestamptz)
    end

    create unique_index(:data_set_fields, [:name, :meta_id])
  end
end
