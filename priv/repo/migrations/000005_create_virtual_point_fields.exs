defmodule Plenario.Repo.Migrations.CreateVirtualPointField do
  use Ecto.Migration

  def change do
    create table(:virtual_point_fields) do
      add :meta_id, references(:metas), null: false
      add :lat_field_id, references(:data_set_fields), default: nil
      add :lon_field_id, references(:data_set_fields), default: nil
      add :loc_field_id, references(:data_set_fields), default: nil
      add :name, :text, null: false

      timestamps(type: :timestamptz)
    end

    create unique_index(
      :virtual_point_fields,
      [
        :meta_id,
        :lat_field_id,
        :lon_field_id,
        :loc_field_id
      ]
    )
  end
end
