defmodule Plenario2.Repo.Migrations.CreateVirtualDateFields do
  use Ecto.Migration

  def change do
    create table(:virtual_date_fields) do
      # field name
      add :name, :text

      # data set fields this references
      add :year_field,    :text,  null: false
      add :month_field,   :text,  default: nil
      add :day_field,     :text,  default: nil
      add :hour_field,    :text,  default: nil
      add :minute_field,  :text,  default: nil
      add :second_field,  :text,  default: nil

      # belongs to meta entry
      add :meta_id, references(:metas)
    end

    create unique_index(:virtual_date_fields, [:meta_id, :name])
  end
end
