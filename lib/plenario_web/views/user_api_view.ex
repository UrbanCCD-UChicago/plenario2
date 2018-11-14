defmodule PlenarioWeb.UserApiView do
  use PlenarioWeb, :view

  def render("user.json", %{user_api: u}) do
    %{
      username: u.username,
      bio: u.bio
    }
  end
end
