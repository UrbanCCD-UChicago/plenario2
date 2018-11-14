defmodule Plenario.Repo.Migrations.CreateDataSets do
  use Ecto.Migration

  def change do
    create table(:data_sets) do
      add :user_id, references(:users, on_delete: :restrict)
      add :name, :text
      add :slug, :text
      add :table_name, :text
      add :view_name, :text
      add :temp_name, :text
      add :soc_4x4, :text, default: nil
      add :soc_domain, :text, default: nil
      add :socrata?, :boolean
      add :src_type, :text, default: nil
      add :src_url, :text, default: nil
      add :state, :text, default: "new"
      add :attribution, :text, default: nil
      add :description, :text, default: nil
      add :refresh_starts_on, :naive_datetime, default: nil
      add :refresh_ends_on, :naive_datetime, default: nil
      add :refresh_interval, :text, default: nil
      add :refresh_rate, :integer, default: nil
      add :first_import, :naive_datetime, default: nil
      add :latest_import, :naive_datetime, default: nil
      add :next_import, :naive_datetime, default: nil
      add :bbox, :geometry, default: nil
      add :hull, :geometry, default: nil
      add :time_range, :tsrange, default: nil
      add :num_records, :integer, default: nil
    end

    create unique_index(:data_sets, :name)

    create unique_index(:data_sets, :src_url)

    create unique_index(:data_sets, [:soc_domain, :soc_4x4], name: :soc_uniq)

    create index(:data_sets, :socrata?)

    create index(:data_sets, :state)

    create index(:data_sets, :refresh_starts_on)

    create index(:data_sets, :refresh_ends_on)

    create index(:data_sets, :latest_import)

    create index(:data_sets, :next_import)

    create index(:data_sets, :time_range)

    create index(:data_sets, :bbox, using: "GIST")

    create index(:data_sets, :hull, using: "GIST")

    create index(:data_sets, :user_id)
  end
end
