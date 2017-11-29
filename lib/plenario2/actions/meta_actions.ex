defmodule Plenario2.Actions.MetaActions do
  import Ecto.Query
  import Plenario2.Queries.Utilities
  alias Plenario2.Changesets.MetaChangesets
  alias Plenario2.Schemas.Meta
  alias Plenario2.Queries.MetaQueries
  alias Plenario2.Repo

  def create(name, user_id, source_url, details \\ []) do
    defaults = [
      source_type: "csv", description: nil, attribution: nil, refresh_rate: nil, refresh_interval: nil,
      refresh_starts_on: nil, refresh_ends_on: nil, srid: 4326, timezone: "UTC"]

    named = [name: name, user_id: user_id, source_url: source_url]

    params = Keyword.merge(defaults, details) |> Keyword.merge(named) |> Enum.into(%{})

    MetaChangesets.create(%Meta{}, params)
    |> Repo.insert()
  end

  defp handle_opts(base, opts \\ []) do
    defaults = [
      with_user: false,
      with_fields: false,
      with_virtual_dates: false,
      with_virtual_points: false,
      with_constraints: false,
      with_diffs: false
    ]
    opts = Keyword.merge(defaults, opts)

    base
    |> cond_compose(opts[:with_user], MetaQueries, :with_user)
    |> cond_compose(opts[:with_fields], MetaQueries, :with_data_set_fields)
    |> cond_compose(opts[:with_virtual_dates], MetaQueries, :with_virtual_date_fields)
    |> cond_compose(opts[:with_virtual_points], MetaQueries, :with_virtual_point_fields)
    |> cond_compose(opts[:with_constraints], MetaQueries, :with_data_set_constraints)
    |> cond_compose(opts[:with_diffs], MetaQueries, :with_data_set_diffs)
  end

  def list(opts \\ []) do
    MetaQueries.list()
    |> handle_opts(opts)
    |> Repo.all()
  end

  def list_for_user(user), do: Repo.all(from m in Meta, where: m.user_id == ^user.id)

  def get_from_pk(pk), do: Repo.one(from m in Meta, where: m.id == ^pk)

  def get_from_slug(slug, opts \\ []) do
    MetaQueries.from_slug(slug)
    |> handle_opts(opts)
    |> Repo.one()
  end

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
      Enum.filter(options, fn({_, value}) -> value != :unchanged end)
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
      Enum.filter(options, fn({_, value}) -> value != :unchanged end)
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
      Enum.filter(options, fn({_, value}) -> value != :unchanged end)
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
        _   -> meta.next_refresh
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
