defmodule Plenario.Repo.Migrations.AddIndexes do
  use Ecto.Migration

  def change do
    # these are both heavily filtered-against fields
    # and deserve proper indexes.
    create index(:metas, :time_range, using: "GIST")
    create index(:metas, :state)

    # same here.
    create index(:aot_metas, :time_range, using: "GIST")
  end
end
