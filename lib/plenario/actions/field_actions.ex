defmodule Plenario.FieldActions do
  import Plenario.ActionUtils

  alias Plenario.{
    DataSet,
    Field,
    FieldQueries,
    Repo
  }

  alias Plenario.Etl.FieldGuesser

  # CRUD

  def list(opts \\ []) do
    FieldQueries.list()
    |> FieldQueries.handle_opts(opts)
    |> Repo.all()
  end

  def get(id, opts \\ []) do
    field =
      FieldQueries.get(id)
      |> FieldQueries.handle_opts(opts)
      |> Repo.one()

    case field do
      nil -> {:error, nil}
      _ -> {:ok, field}
    end
  end

  def get!(id, opts \\ []) do
    FieldQueries.get(id)
    |> FieldQueries.handle_opts(opts)
    |> Repo.one!()
  end

  def create(params) do
    params =
      params_to_map(params)
      |> parse_relation(:data_set)

    Field.changeset(%Field{}, params)
    |> Repo.insert()
  end

  def update(field, params) do
    params =
      params_to_map(params)
      |> parse_relation(:data_set)

    Field.changeset(field, params)
    |> Repo.update()
  end

  def delete(field), do: Repo.delete(field)

  # Other Functions

  def create_for_data_set(%DataSet{} = ds) do
    FieldGuesser.guess(ds)
    |> Enum.reduce(Ecto.Multi.new(), fn params, multi ->
      Ecto.Multi.insert(multi, "insert #{ds.id} #{params[:name]}", Field.changeset(%Field{}, Map.put(params, :data_set_id, ds.id)))
    end)
    |> Repo.transaction()
  end
end
