defmodule Plenario.Repo.Migrations.CreateParserFuncs do
  use Ecto.Migration

  def up do
    # parse lat/lon field pair
    execute """
    CREATE OR REPLACE FUNCTION parse_lat_lon(lat FLOAT, lon FLOAT)
    RETURNS GEOMETRY(POINT, 4326) AS $$
      SELECT st_pointfromtext( 'POINT(' || lon || ' ' || lat || ')', 4326 )
    $$ LANGUAGE sql IMMUTABLE;
    """

    # parse loc string
    execute """
    CREATE OR REPLACE FUNCTION parse_loc(loc TEXT)
    RETURNS GEOMETRY(POINT, 4326) AS $$
      SELECT st_pointfromtext( 'POINT(' || subq.lon || ' ' || subq.lat || ')', 4326 )
      FROM (
        SELECT
          FLOAT8((regexp_matches(loc, '\\((.*),.*\\)'))[1]) AS lat,
          FLOAT8((regexp_matches(loc, '\\(.*,(.*)\\)'))[1]) AS lon
      ) AS subq
    $$ LANGUAGE sql IMMUTABLE;
    """

    # parse timestamp from fields
    execute """
    CREATE OR REPLACE FUNCTION parse_timestamptz(
      year INTEGER,
      month INTEGER,
      day INTEGER,
      hour INTEGER,
      minute INTEGER,
      second INTEGER
    )
    RETURNS TIMESTAMPTZ AS $$
      SELECT make_timestamptz(
        year,
        (CASE WHEN month IS NULL THEN 1 ELSE month END),
        (CASE WHEN day IS NULL THEN 1 ELSE day END),
        (CASE WHEN hour IS NULL THEN 0 ELSE hour END),
        (CASE WHEN minute IS NULL THEN 0 ELSE minute END),
        (CASE WHEN second IS NULL THEN 0 ELSE second END),
        'UTC'
      )
    $$ LANGUAGE sql IMMUTABLE;
    """
  end

  def down do
    execute """
    DROP FUNCTION IF EXISTS parse_lat_lon(float, float) CASCADE;
    """

    execute """
    DROP FUNCTION IF EXISTS parse_loc(text) CASCADE;
    """

    execute """
    DROP FUNCTION IF EXISTS parse_timestamptz(integer, integer, integer, integer, integer, integer) CASCADE;
    """
  end
end
