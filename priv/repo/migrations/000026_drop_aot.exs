defmodule Plenario.Repo.Migrations.DropAot do
  use Ecto.Migration

  def change do
    drop_if_exists table(:aot_observations)
    drop_if_exists table(:aot_data)
    drop_if_exists table(:aot_metas)
  end
end
