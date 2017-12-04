defmodule Plenario2Auth.UserQueries do
  import Ecto.Query
  alias Plenario2Auth.User

  def list(), do: (from u in User)

  def active(query), do: from u in query, where: u.is_active == true

  def archived(query), do: from u in query, where: u.is_active == false

  def trusted(query), do: from u in query, where: u.is_trusted == true

  def admin(query), do: from u in query, where: u.is_admin == true
end
