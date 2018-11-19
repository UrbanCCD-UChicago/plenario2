defmodule Plenario.Repo.Migrations.CreateFields do
  use Ecto.Migration

  def change do
    create table(:fields) do
      add :name, :text
      add :col_name, :text
      add :type, :text
      add :description, :text
      add :data_set_id, references(:data_sets, on_delete: :delete_all)
    end

    create index(:fields, :data_set_id)
  end
end
