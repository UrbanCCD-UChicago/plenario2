defmodule Plenario.Repo.Migrations.DropAot do
  use Ecto.Migration

  def change do
    drop_if_exists table(:aot_metas)
    drop_if_exists table(:aot_data)
    drop_if_exists table(:aot_observations)
  end
end
