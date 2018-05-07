defmodule Plenario.Repo.Migrations.CreateAotObservations do
  use Ecto.Migration

  def change do
    create table(:aot_observations) do
      # FK to data
      add :aot_data_id, references(:aot_data), null: false

      # broken down observation json
      add :path, :text, null: false
      add :sensor, :text, null: false
      add :observation, :text, null: false
      add :value, :float, null: false
    end

    create index(:aot_observations, [:path])
    create index(:aot_observations, [:sensor])
    create index(:aot_observations, [:observation])
    create unique_index(:aot_observations, [:aot_data_id, :path])
  end
end
