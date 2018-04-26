defmodule PlenarioWeb.Controllers.Api.Condition do
  import Ecto.Query
  import Ecto.Query.API

  def bbox_query(query, {column, {"in", %{coordinates: coordinates, srid: srid}}}) do
    linestring =
      coordinates
      |> Enum.map(fn [x, y] -> "#{x} #{y}" end)
      |> Enum.join(",")
      |> (&("LINESTRING(#{&1})")).()
    from(r in query, where: fragment("ST_Contains(?, ST_Polygon(?, ?))", field(r, ^column), ^linestring, ^srid))
  end
end
