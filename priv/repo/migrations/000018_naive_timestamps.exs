defmodule Plenario.Repo.Migrations.MakeTimestampsNaive do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:metas) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
      remove :time_range
      add :time_range, :tsrange
    end

    alter table(:data_set_fields) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:virtual_date_fields) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:virtual_point_fields) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:etl_jobs) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:export_jobs) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    alter table(:admin_user_notes) do
      modify :inserted_at, :timestamp
      modify :updated_at, :timestamp
    end

    # alter table(:aot_metas) do
    #   remove :time_range
    #   add :time_range, :tsrange
    # end
  end
end
