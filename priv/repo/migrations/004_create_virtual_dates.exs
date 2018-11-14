defmodule Plenario.Repo.Migrations.CreateVirtualDates do
  use Ecto.Migration

  def change do
    create table(:virtual_dates) do
      add :col_name, :string
      add :data_set_id, references(:data_sets, on_delete: :delete_all)
      add :yr_field_id, references(:fields, on_delete: :delete_all)
      add :mo_field_id, references(:fields, on_delete: :delete_all)
      add :day_field_id, references(:fields, on_delete: :delete_all)
      add :hr_field_id, references(:fields, on_delete: :delete_all)
      add :min_field_id, references(:fields, on_delete: :delete_all)
      add :sec_field_id, references(:fields, on_delete: :delete_all)
    end

    create index(:virtual_dates, :data_set_id)

    create index(:virtual_dates, :yr_field_id)

    create index(:virtual_dates, :mo_field_id)

    create index(:virtual_dates, :day_field_id)

    create index(:virtual_dates, :hr_field_id)

    create index(:virtual_dates, :min_field_id)

    create index(:virtual_dates, :sec_field_id)
  end
end
