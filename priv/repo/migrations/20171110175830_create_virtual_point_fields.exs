defmodule Plenario.Repo.Migrations.CreateVirtualPointFields do
  use Ecto.Migration

  def change do
    create table(:virtual_point_fields) do
      # field name
      add :name, :text

      # data set fields this references
      add :longitude_field, :text,  default: nil
      add :latitude_field,  :text,  default: nil
      add :location_field,  :text,  default: nil

      # belongs to meta entry
      add :meta_id, references(:metas)
    end

    create unique_index(:virtual_point_fields, [:meta_id, :name])
  end
end
