defmodule Plenario.Repo.Migrations.DropUniqueConstraints do
  use Ecto.Migration

  def change do
    drop table(:data_set_diffs)
    drop table(:unique_constraints)
  end
end
