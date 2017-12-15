defmodule Geojson do
  def from_exshape(%Exshape.Shp.Polygon{points: points}) do
    coordinates = 
      for level1 <- points do
        for level2 <- level1 do
          for %Exshape.Shp.Point{x: x, y: y} <- level2 do
            {x, y}
          end
        end
      end

      """
      {
        "type": "Polygon",
        "coordinates": [
          [
            [
              -87.52498626708983,
              41.651879827111344
            ],
            [
              -87.39555358886719,
              41.651879827111344
            ],
            [
              -87.39555358886719,
              41.70624114327587
            ],
            [
              -87.52498626708983,
              41.70624114327587
            ],
            [
              -87.52498626708983,
              41.651879827111344
            ]
          ]
        ]
      }
      """
  end
end
