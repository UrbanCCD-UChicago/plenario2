defmodule PlenarioWeb.Controllers.Api.ConditionTest do
  alias Plenario.ModelRegistry
  import PlenarioWeb.Controllers.Api.Condition
  use ExUnit.Case

  setup do

  end

  test "generates a geospatial query using a bounding box", %{meta: meta} do
    coordinates = [[0, 0], [100, 0], [100, 100], [0, 100], [0, 0]]
    condition = {"point", {"in"}}
    # geojson = %{type: "Polygon", coordinates: bbox, srid: 4326}
    IO.inspect bbox_query(coordinates)
  end
end
