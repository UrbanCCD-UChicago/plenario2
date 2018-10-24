defmodule Plenario.Repo.Migrations.CreateAotData do
  use Ecto.Migration

  def change do
    # create table(:aot_data) do
    #   # FK to meta
    #   add :aot_meta_id, references(:aot_metas), null: false

    #   # json payload fields
    #   add :node_id, :text, null: false
    #   add :human_address, :text
    #   add :latitude, :float, null: false
    #   add :longitude, :float, null: false
    #   add :timestamp, :timestamp, null: false
    #   add :observations, :jsonb, null: false

    #   # parsed location from lat/lon
    #   add :location, :geometry, null: false

    #   # insert/update timestamps
    #   timestamps()
    # end

    # create index(:aot_data, [:node_id])
    # create index(:aot_data, [:timestamp])
    # create index(:aot_data, [:location])
    # create unique_index(:aot_data, [:aot_meta_id, :node_id, :timestamp])
  end
end
