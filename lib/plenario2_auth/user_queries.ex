defmodule Plenario2Auth.UserQueries do
  import Ecto.Query
  alias Plenario2Auth.User

  def get_by_id(id), do: from u in User, where: u.id == ^id

  def get_by_email(email), do: from u in User, where: u.email_address == ^email

  def list(), do: (from u in User)

  def active(query), do: from u in query, where: u.is_active == true

  def archived(query), do: from u in query, where: u.is_active == false

  def trusted(query), do: from u in query, where: u.is_trusted == true

  def admin(query), do: from u in query, where: u.is_admin == true

  def with_metas(query), do: from u in query, preload: [metas: :metas]
end
