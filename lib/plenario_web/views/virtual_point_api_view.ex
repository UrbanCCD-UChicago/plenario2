defmodule PlenarioWeb.VirtualPointApiView do
  use PlenarioWeb, :view

  def render("virtual_point.json", %{virtual_point_api: p}) do
    %{
      col_name: p.col_name,
      loc_field_id: p.loc_field_id,
      lon_field_id: p.lon_field_id,
      lat_field_id: p.lat_field_id
    }
  end
end
