defmodule PlenarioWeb.ErrorView do
  use PlenarioWeb, :web_view

  def render("403.html", _) do
    render("403_page.html", %{})
  end

  def render("404.html", _) do
    render("404_page.html", %{})
  end

  def render("500.html", _) do
    render("500_page.html", %{})
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render("500.html", assigns)
  end
end
