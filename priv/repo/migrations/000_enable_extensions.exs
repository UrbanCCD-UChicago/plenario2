defmodule Plenario.Repo.Migrations.EnableExtensions do
  use Ecto.Migration

  def up do
    execute """
    CREATE EXTENSION IF NOT EXISTS postgis
    """

    execute """
    CREATE EXTENSION IF NOT EXISTS pg_trgm
    """

    execute """
    CREATE EXTENSION IF NOT EXISTS tsm_system_rows
    """
  end
end
