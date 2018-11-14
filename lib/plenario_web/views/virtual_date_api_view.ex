defmodule PlenarioWeb.VirtualDateApiView do
  use PlenarioWeb, :view

  def render("virtual_date.json", %{virtual_date_api: d}) do
    %{
      col_name: d.col_name,
      yr_field_id: d.yr_field_id,
      mo_field_id: d.mo_field_id,
      day_field_id: d.day_field_id,
      hr_field_id: d.hr_field_id,
      min_field_id: d.min_field_id,
      sec_field_id: d.sec_field_id
    }
  end
end
