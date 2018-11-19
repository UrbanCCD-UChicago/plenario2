defmodule PlenarioWeb.FieldApiView do
  use PlenarioWeb, :view

  def render("field.json", %{field_api: f}) do
    %{
      name: f.name,
      col_name: f.col_name,
      type: f.type,
      description: f.description
    }
  end
end
