defmodule Plenario2.Repo.Migrations.PostGISExtension do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION postgis;"
  end
end
