defmodule Plenario.Repo.Migrations.EnableTsmSystemRows do
  use Ecto.Migration

  def up do
    execute """
    CREATE EXTENSION IF NOT EXISTS tsm_system_rows;
    """
  end
end
