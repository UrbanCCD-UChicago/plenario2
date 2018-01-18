defmodule Plenario2Etl.Shapefile do
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
  The table is either created or replaced for the database configured for
  `Plenario2.Repo`.
  """
  def load(path, table) do
    host = Application.get_env(:plenario2, Plenario2.Repo)[:hostname]
    user = Application.get_env(:plenario2, Plenario2.Repo)[:username]
    password = Application.get_env(:plenario2, Plenario2.Repo)[:password]
    db = Application.get_env(:plenario2, Plenario2.Repo)[:database]
    dbconn = "PG:host=#{host} user=#{user} dbname=#{db} password=#{password}"

    args = ["-f", "PostgreSQL", dbconn, path, "-lco", "GEOMETRY_NAME=geom",
      "-lco", "FID=gid", "-lco", "PRECISION=no", "-nlt", "PROMOTE_TO_MULTI",
      "-nln", table, "-overwrite"]

    case System.cmd("ogr2ogr", args) do
      {"", 0} -> {:ok, table}
      {error, 1} -> {:error, error}
    end
  end
end
