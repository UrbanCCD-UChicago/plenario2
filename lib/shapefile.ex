defmodule Shapefile do
  @moduledoc """
  Explicitly defines this application's interface with shapefiles. By creating
  this contract, we can be flexible with the methods by which we ingest shapes.
  The methods can be substituted with one another, and as long as the interface
  does not change, we can avoid breaking things.

  For information on this design pattern, check out [this blogpost](http://bl
  og.plataformatec.com.br/2015/10/mocks-and-explicit-contracts/) by Mr. Valim.
  """

  @doc """
  Loads records from an unzipped shapefile at `path` to a table named `table`.
  The table is either created or replaced for the database identified by the
  `connection` string.

  ## Examples

      iex> Shapefile.load(
      ...>   "/tmp/shapefile", 
      ...>   "shapefile",
      ...>   "postgresql://postgres:password@localhost:5432/plenario2_test"
      ...> )
      :ok
      
  """
  def load(path, table, connection) do
    args = [
      "-f", "PostgreSQL",
      "-lco", "PRECISION=no",
      "-nlt", "PROMOTE_TO_MULTI",
      "-s_srs", path <> ".prj",
      "-t_srs", "EPSG:4326",
      connection, path <> ".shp",
      "-nln", table,
      "-lco", "GEOMETRY_NAME=geom"
    ]

    System.cmd("ogr2ogr", args)
  end
end
