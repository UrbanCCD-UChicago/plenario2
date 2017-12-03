defmodule Plenario2.Actions.MetaActions do
  alias Plenario2.Changesets.MetaChangesets
  alias Plenario2.Queries.MetaQueries, as: Q
  alias Plenario2.Schemas.Meta
  alias Plenario2.Repo

  ##
  # get one

  def get_from_id(id, opts \\ []) do
    Q.from_id(id)
    |> Q.handle_opts(opts)
    |> Repo.one()
  end

  def get_from_slug(slug, opts \\ []) do
    Q.from_slug(slug)
    |> Q.handle_opts(opts)
    |> Repo.one()
  end

  ##
  # get list

  def list(opts \\ []) do
    Q.list()
    |> Q.handle_opts(opts)
    |> Repo.all()
  end

  def list_for_user(user, opts \\ []) do
    local_defaults = [with_user: true, for_user: user]
    opts = Keyword.merge(local_defaults, opts)

    Q.list()
    |> Q.handle_opts(opts)
    |> Repo.all()
  end

  ##
  # create

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

    params = Keyword.merge(defaults, details)
    |> Keyword.merge(named)
    |> Enum.into(%{})

    MetaChangesets.create(%Meta{}, params)
    |> Repo.insert()
  end

  ##
  # update

  def update_name(meta, new_name) do
    MetaChangesets.update_name(meta, %{name: new_name})
    |> Repo.update()
  end

  def update_user(meta, user) do
    MetaChangesets.update_user(meta, %{user_id: user.id})
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

  ##
  # states

  def submit_for_approval(meta) do
    Meta.submit_for_approval(meta)
    |> Repo.update()
  end

  def approve(meta) do
    Meta.approve(meta)
    |> Repo.update()
  end

  def disapprove(meta) do
    Meta.disapprove(meta)
    |> Repo.update()
  end

  def mark_erred(meta) do
    Meta.mark_erred(meta)
    |> Repo.update()
  end

  def mark_fixed(meta) do
    Meta.mark_fixed(meta)
    |> Repo.update()
  end

  ##
  # deletion

  def delete(meta), do: Repo.delete(meta)
end
