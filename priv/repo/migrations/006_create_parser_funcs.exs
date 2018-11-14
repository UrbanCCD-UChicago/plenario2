defmodule Plenario.Repo.Migrations.CreateParserFuncs do
  use Ecto.Migration

  def up do
    execute """
    CREATE OR REPLACE FUNCTION p_timestamp_from_text (value TEXT)
    RETURNS timestamp AS $$
    BEGIN
      RETURN value::timestamp;
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION p_timestamp_from_ymdhms (
      yr TEXT, mo TEXT DEFAULT '01', day TEXT DEFAULT '01',
      hr TEXT DEFAULT '00', min TEXT DEFAULT '00', sec TEXT DEFAULT '00'
    )
    RETURNS timestamp AS $$
    BEGIN
      RETURN (yr || '-' || mo || '-' || day || ' ' || hr || ':' || min || ':' || sec)::timestamp;
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION p_integer_from_text (value TEXT)
    RETURNS bigint AS $$
    BEGIN
      RETURN value::bigint;
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION p_float_from_text (value TEXT)
    RETURNS float AS $$
    BEGIN
      RETURN value::float;
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION p_boolean_from_text (value TEXT)
    RETURNS boolean AS $$
    BEGIN
      RETURN value::boolean;
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION p_jsonb_from_text (value TEXT)
    RETURNS jsonb AS $$
    BEGIN
      RETURN value::jsonb;
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    # thanks socrata -- i really love how you've bucked convention and
    # turned coordinate strings to lat/lon rather than the standard
    # lon/lat. jesus h tap dancing christ...

    execute """
    CREATE OR REPLACE FUNCTION p_point_from_loc (value TEXT)
    RETURNS GEOMETRY(POINT, 4326) AS $$
    BEGIN
      RETURN st_pointfromtext( 'POINT(' || subq.lon || ' ' || subq.lat || ')', 4326 )
      FROM (
        SELECT
          FLOAT8((regexp_matches(value, '\\(?\\s*?([+-]?\\d+\\.?\\d+)\\s*?,.*'))[1]) AS lat,
          FLOAT8((regexp_matches(value, '.*,\\s*?([+-]?\\d+\\.?\\d+)\\s*?\\)?'))[1]) AS lon
      ) AS subq;
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION p_point_from_lon_lat (lon TEXT, lat TEXT)
    RETURNS GEOMETRY(POINT, 4326) AS $$
    BEGIN
      RETURN st_pointfromtext( 'POINT(' || lon || ' ' || lat || ')', 4326 );
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """

    execute """
    CREATE OR REPLACE FUNCTION p_geom_from_text (text TEXT)
    RETURNS GEOMETRY AS $$
    BEGIN
      RETURN st_geomfromtext(text, 4326);
      EXCEPTION WHEN others THEN RETURN null;
    END
    $$
    LANGUAGE plpgsql
    """
  end

  def down do
    execute """
    DROP FUNCTION p_timestamp_from_text (TEXT)
    """

    execute """
    DROP FUNCTION p_timestamp_from_ymdhms (TEXT, TEXT, TEXT, TEXT, TEXT, TEXT)
    """

    execute """
    DROP FUNCTION p_integer_from_text (TEXT)
    """

    execute """
    DROP FUNCTION p_float_from_text (TEXT)
    """

    execute """
    DROP FUNCTION p_boolean_from_text (TEXT)
    """

    execute """
    DROP FUNCTION p_point_from_loc (TEXT)
    """

    execute """
    DROP FUNCTION p_point_from_lon_lat (TEXT, TEXT)
    """

    execute """
    DROP FUNCTION p_geom_from_text (TEXT)
    """
  end
end
