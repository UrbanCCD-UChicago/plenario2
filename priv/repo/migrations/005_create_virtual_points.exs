defmodule Plenario.Repo.Migrations.CreateVirtualPoints do
  use Ecto.Migration

  def change do
    create table(:virtual_points) do
      add :col_name, :string
      add :data_set_id, references(:data_sets, on_delete: :delete_all)
      add :loc_field_id, references(:fields, on_delete: :delete_all)
      add :lon_field_id, references(:fields, on_delete: :delete_all)
      add :lat_field_id, references(:fields, on_delete: :delete_all)
    end

    create index(:virtual_points, :data_set_id)

    create index(:virtual_points, :loc_field_id)

    create index(:virtual_points, :lon_field_id)

    create index(:virtual_points, :lat_field_id)
  end
end
