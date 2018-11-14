defmodule Plenario.VirtualDateActions do
  import Plenario.ActionUtils

  alias Plenario.{
    Repo,
    VirtualDate,
    VirtualDateQueries
  }

  # CRUD

  def list(opts \\ []) do
    VirtualDateQueries.list()
    |> VirtualDateQueries.handle_opts(opts)
    |> Repo.all()
  end

  def get(id, opts \\ []) do
    date =
      VirtualDateQueries.get(id)
      |> VirtualDateQueries.handle_opts(opts)
      |> Repo.one()

    case date do
      nil -> {:error, nil}
      _ -> {:ok, date}
    end
  end

  def get!(id, opts \\ []) do
    VirtualDateQueries.get(id)
    |> VirtualDateQueries.handle_opts(opts)
    |> Repo.one!()
  end

  def create(params) do
    params =
      params_to_map(params)
      |> parse_relation(:data_set)
      |> parse_relation(:yr_field)
      |> parse_relation(:mo_field)
      |> parse_relation(:day_field)
      |> parse_relation(:hr_field)
      |> parse_relation(:min_field)
      |> parse_relation(:sec_field)

    VirtualDate.changeset(%VirtualDate{}, params)
    |> Repo.insert()
  end

  def update(date, params) do
    params =
      params_to_map(params)
      |> parse_relation(:data_set)
      |> parse_relation(:yr_field)
      |> parse_relation(:mo_field)
      |> parse_relation(:day_field)
      |> parse_relation(:hr_field)
      |> parse_relation(:min_field)
      |> parse_relation(:sec_field)

    VirtualDate.changeset(date, params)
    |> Repo.update()
  end

  def delete(date), do: Repo.delete(date)
end
