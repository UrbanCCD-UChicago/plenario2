defmodule Plenario.UserQueries do
  import Ecto.Query

  import Plenario.QueryUtils

  alias Plenario.{
    User,
    UserQueries
  }

  def list, do: from u in User

  def get(id) do
    case Regex.match?(~r/^\d+$/, "#{id}") do
      true -> from u in User, where: u.id == ^id
      false -> from u in User, where: u.email == ^id
    end
  end

  def assert_is_admin(query), do: from u in query, where: u.is_admin? == true

  def with_data_sets(query), do: from u in query, preload: [:data_sets]

  def handle_opts(query, opts \\ []) do
    opts = [
      assert_is_admin: false,
      with_data_sets: false
    ]
    |> Keyword.merge(opts)

    query
    |> boolean_compose(opts[:assert_is_admin], UserQueries, :assert_is_admin)
    |> boolean_compose(opts[:with_data_sets], UserQueries, :with_data_sets)
  end
end
