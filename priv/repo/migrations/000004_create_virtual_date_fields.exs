defmodule Plenario.Repo.Migrations.CreateVirtualDateField do
  use Ecto.Migration

  def change do
    create table(:virtual_date_fields) do
      add :meta_id, references(:metas), null: false
      add :year_field_id, references(:data_set_fields), null: false
      add :month_field_id, references(:data_set_fields), default: nil
      add :day_field_id, references(:data_set_fields), default: nil
      add :hour_field_id, references(:data_set_fields), default: nil
      add :minute_field_id, references(:data_set_fields), default: nil
      add :second_field_id, references(:data_set_fields), default: nil
      add :name, :text, null: false

      timestamps(type: :timestamptz)
    end

    create unique_index(
      :virtual_date_fields,
      [
        :meta_id,
        :year_field_id,
        :month_field_id,
        :day_field_id,
        :hour_field_id,
        :minute_field_id,
        :second_field_id
      ]
    )
  end
end
