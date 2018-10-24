defmodule Plenario.Repo.Migrations.CreateAotMetas do
  use Ecto.Migration

  def change do
    # create table(:aot_metas) do
    #   # basic info
    #   add :network_name, :text, null: false
    #   add :slug, :text, null: false
    #   add :source_url, :text, null: false

    #   # computed fields
    #   add :bbox, :geometry, default: nil
    #   add :time_range, :tstzrange, default: nil

    #   # insert/update timestamps
    #   timestamps()
    # end

    # create index(:aot_metas, [:bbox])
    # create index(:aot_metas, [:time_range])
    # create unique_index(:aot_metas, [:network_name])
    # create unique_index(:aot_metas, [:slug])
    # create unique_index(:aot_metas, [:source_url])
  end
end
