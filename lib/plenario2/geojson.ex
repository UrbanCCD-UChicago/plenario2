defmodule Geojson do
  def from_exshape(%Exshape.Shp.Polygon{points: points}) do
    [ [ points | _ ] | _ ] = points

    coordinates = 
      Enum.map(points, fn %Exshape.Shp.Point{x: x, y: y} ->
        [x, y]
      end)

    %{
      "type" => "Polygon",
      "coordinates" => [coordinates]
    }
  end
end
