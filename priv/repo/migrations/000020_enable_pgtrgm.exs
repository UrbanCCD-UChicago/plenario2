defmodule Plenario.Repo.Migrations.EnablePgTrgm do
  use Ecto.Migration

  def up do
    execute """
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    """
  end
end
