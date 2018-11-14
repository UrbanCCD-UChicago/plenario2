defmodule Plenario.VirtualPointActions do
  import Plenario.ActionUtils

  alias Plenario.{
    Repo,
    VirtualPoint,
    VirtualPointQueries
  }

  # CRUD

  def list(opts \\ []) do
    VirtualPointQueries.list()
    |> VirtualPointQueries.handle_opts(opts)
    |> Repo.all()
  end

  def get(id, opts \\ []) do
    point =
      VirtualPointQueries.get(id)
      |> VirtualPointQueries.handle_opts(opts)
      |> Repo.one()

    case point do
      nil -> {:error, nil}
      _ -> {:ok, point}
    end
  end

  def get!(id, opts \\ []) do
    VirtualPointQueries.get(id)
    |> VirtualPointQueries.handle_opts(opts)
    |> Repo.one!()
  end

  def create(params) do
    params =
      params_to_map(params)
      |> parse_relation(:data_set)
      |> parse_relation(:loc_field)
      |> parse_relation(:lon_field)
      |> parse_relation(:lat_field)

    VirtualPoint.changeset(%VirtualPoint{}, params)
    |> Repo.insert()
  end

  def update(point, params) do
    params =
      params_to_map(params)
      |> parse_relation(:data_set)
      |> parse_relation(:loc_field)
      |> parse_relation(:lon_field)
      |> parse_relation(:lat_field)

    VirtualPoint.changeset(point, params)
    |> Repo.update()
  end

  def delete(point), do: Repo.delete(point)
end
