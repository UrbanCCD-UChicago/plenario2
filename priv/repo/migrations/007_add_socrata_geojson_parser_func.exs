defmodule Plenario.Repo.Migrations.AddSocrataGeoJsonParserFunc do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION p_geom_from_geojson (text TEXT)
    RETURNS GEOMETRY AS $$
    BEGIN
      RETURN st_geomfromgeojson(text);
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """
  end

  def down do
    execute """
    DROP FUNCTION p_geom_from_geojson (TEXT)
    """
  end
end
