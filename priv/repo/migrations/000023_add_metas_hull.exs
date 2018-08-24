defmodule Plenario.Repo.Migrations.AddMetasHull do
  use Ecto.Migration

  def change do
    alter table(:metas) do
      add :hull, :geometry, default: nil
    end

    create index(:metas, :bbox, using: "GIST")

    create index(:metas, :hull, using: "GIST")
  end
end
