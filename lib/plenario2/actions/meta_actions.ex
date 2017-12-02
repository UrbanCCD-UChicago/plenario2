defmodule Plenario2.Actions.MetaActions do
  import Ecto.Query
  alias Plenario2.Changesets.MetaChangesets
  alias Plenario2.Schemas.{
    DataSetConstraint,
    Meta
  }
  alias Plenario2.Repo

  def create(name, user_id, source_url, details \\ []) do
    defaults = [
      source_type: "csv",
      description: nil,
      attribution: nil,
      refresh_rate: nil,
      refresh_interval: nil,
      refresh_starts_on: nil,
      refresh_ends_on: nil,
      srid: 4326,
      timezone: "UTC"
    ]

    named = [name: name, user_id: user_id, source_url: source_url]

    params = Keyword.merge(defaults, details) |> Keyword.merge(named) |> Enum.into(%{})

    MetaChangesets.create(%Meta{}, params)
    |> Repo.insert()
  end

  def list(), do: Repo.all(Meta)

  def list_for_user(user), do: Repo.all(from(m in Meta, where: m.user_id == ^user.id))

  def get_from_pk(pk), do: Repo.one(from(m in Meta, where: m.id == ^pk))

  @doc """
  Load a single row of `Meta` with any field specified by `preloads`
  preloaded.

  ## Examples

    iex> get_by_pk_preload(1)
    iex> get_by_pk_preload(1, [:data_set_constraints])
    iex> get_by_pk_preload(1, [:data_set_constraints, :data_set_diffs])

  """
  @spec get_by_pk_preload(pk :: integer, preloads :: list) :: Meta
  def get_by_pk_preload(pk, preloads \\ []) do
    Repo.one(
      from(
        m in Meta,
        where: m.id == ^pk,
        preload: ^preloads
      )
    )
  end

  @doc """
  Get a list of column names for a `Meta` struct. 

  ## Examples

    iex> get_columns(meta)
    ["id", "location", "datetime", "observation"]

  """
  @spec get_columns(meta :: Meta) :: list[charlist]
  def get_columns(meta) do
    meta = Repo.preload(meta, :data_set_fields)
    for field <- meta.data_set_fields() do
      field.name()
    end
  end

  @doc """
  Get the first constraint association for the given `meta`.

  ## Examples

    iex> get_constraint(meta)
    %DataSetConstraint{}

  """
  @spec get_constraint(meta :: Meta) :: DataSetConstraint
  def get_constraint(meta) do
    meta = Repo.preload(meta, :data_set_constraints)
    [constraint | _] = meta.data_set_constraints()
    constraint
  end

  @doc """
  Get the list of keys specified by the first `DataSetStraint` association
  of a `Meta` struct.

  ## Examples

    iex> get_constraints(meta)
    ["datetime", "location"]

  """
  @spec get_constraints(meta :: Meta) :: list[charlist]
  def get_constraints(meta) do
    get_constraint(meta).field_names()
  end

  def get_from_slug(slug), do: Repo.one(from(m in Meta, where: m.slug == ^slug))

  def update_name(meta, new_name) do
    MetaChangesets.update_name(meta, %{name: new_name})
    |> Repo.update()
  end

  def update_user(meta, user_id) do
    MetaChangesets.update_user(meta, %{user_id: user_id})
    |> Repo.update()
  end

  def update_source_info(meta, options \\ []) do
    defaults = [
      source_url: :unchanged,
      source_type: :unchanged
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    params =
      Enum.filter(options, fn {_, value} -> value != :unchanged end)
      |> Enum.into(%{})

    MetaChangesets.update_source_info(meta, params)
    |> Repo.update()
  end

  def update_description_info(meta, options \\ []) do
    defaults = [
      description: :unchanged,
      attribution: :unchanged
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    params =
      Enum.filter(options, fn {_, value} -> value != :unchanged end)
      |> Enum.into(%{})

    MetaChangesets.update_description_info(meta, params)
    |> Repo.update()
  end

  def update_refresh_info(meta, options \\ []) do
    defaults = [
      refresh_rate: :unchanged,
      refresh_interval: :unchanged,
      refresh_starts_on: :unchanged,
      refresh_ends_on: :unchanged
    ]

    options = Keyword.merge(defaults, options) |> Enum.into(%{})

    params =
      Enum.filter(options, fn {_, value} -> value != :unchanged end)
      |> Enum.into(%{})

    MetaChangesets.update_refresh_info(meta, params)
    |> Repo.update()
  end

  # todo: implement after setting up ds table and get rows
  # def update_bbox(meta), do: meta

  # todo: implement after setting up ds table and get rows
  # def update_timerange(meta), do: meta

  def update_next_refresh(meta) do
    current =
      case meta.next_refresh do
        nil -> DateTime.utc_now()
        _ -> meta.next_refresh
      end

    rate = meta.refresh_rate
    interval = meta.refresh_interval

    shifted = Timex.shift(current, [{String.to_atom(rate), interval}])
    params = %{next_refresh: shifted}

    MetaChangesets.update_next_refresh(meta, params)
    |> Repo.update()
  end

  def delete(meta), do: Repo.delete(meta)
end
