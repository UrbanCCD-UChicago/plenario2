defmodule Plenario.Repo.Migrations.AddAoTMetasHull do
  use Ecto.Migration

  def change do
    alter table(:aot_metas) do
      add :hull, :geometry, default: nil
    end

    # the migration that creates the table has an index,
    # but it uses the default b-tree index type which is
    # __not__ what we want for geoms.
    drop index(:aot_metas, :bbox)
    create index(:aot_metas, :bbox, using: "GIST")

    create index(:aot_metas, :hull, using: "GIST")
  end
end
