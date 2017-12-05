defmodule Plenario2.Actions.MetaActions do
  alias Plenario2Auth.User

  alias Plenario2.Changesets.MetaChangesets
  alias Plenario2.Queries.MetaQueries, as: Q
  alias Plenario2.Actions.AdminUserNoteActions
  alias Plenario2.Schemas.{Meta, DataSetConstraint}
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

  @doc """
  Get a list of column names for a `Meta` struct.

  ## Examples

    iex> get_column_names(meta)
    ["id", "location", "datetime", "observation"]

  """
  @spec get_column_names(meta :: Meta) :: list[charlist]
  def get_column_names(meta) do
    meta = Repo.preload(meta, :data_set_fields)
    for field <- meta.data_set_fields() do
      field.name
    end
  end

  @doc """
  Get a slugified version of `meta.name`.

  ## Examples

    iex> get_data_set_table_name(meta)
    "chicago_tree_trimmings"

  """
  @spec get_data_set_table_name(meta :: Meta) :: charlist
  def get_data_set_table_name(meta) do
    meta.name
    |> String.split(~r/\s/, trim: true)
    |> Enum.map(&String.downcase/1)
    |> Enum.join("_")
  end

  @doc """
  Get the first constraint association for the given `meta`.

  ## Examples

    iex> get_first_constraint(meta)
    %DataSetConstraint{}

  """
  @spec get_first_constraint(meta :: Meta) :: DataSetConstraint
  def get_first_constraint(meta) do
    meta = Repo.preload(meta, :data_set_constraints)
    [constraint | _] = meta.data_set_constraints
    constraint
  end

  @doc """
  Get the list of keys specified by the first `DataSetStraint` association
  of a `Meta` struct.

  ## Examples

    iex> get_first_constraint_field_names(meta)
    ["datetime", "location"]

  """
  @spec get_first_constraint_field_names(meta :: Meta) :: list[charlist]
  def get_first_constraint_field_names(meta) do
    get_first_constraint(meta).field_names
  end

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

  ##
  # states

  def submit_for_approval(meta) do
    Meta.submit_for_approval(meta)
    |> Repo.update()
  end

  def approve(meta, %User{is_admin: true} = admin) do
    AdminUserNoteActions.create_for_meta(
      "Your data set has been approved",
      admin, meta.user, meta, false
    )

    Meta.approve(meta)
    |> Repo.update()
  end

  def approve(meta, admin), do: {:error, "#{admin.name} is not an admin"}

  def disapprove(meta, %User{is_admin: true} = admin, message) do
    msg = "Approval has been denied:\n\n" <> message
    AdminUserNoteActions.create_for_meta(
      msg, admin, meta.user, meta, true
    )

    Meta.disapprove(meta)
    |> Repo.update()
  end

  def disapprove(meta, admin, _), do: {:error, "#{admin.name} is not an admin"}

  def mark_erred(meta, %User{is_admin: true} = admin, message) do
    msg = "An error occurred regarding your data set:\n\n" <> message
    AdminUserNoteActions.create_for_meta(
      msg, admin, meta.user, meta, true
    )

    Meta.mark_erred(meta)
    |> Repo.update()
  end

  def mark_erred(meta, admin, _), do: {:error, "#{admin.name} is not an admin"}

  def mark_fixed(meta, %User{is_admin: true} = admin, message) do
    msg = "Data set error fixed:\n\n" <> message
    AdminUserNoteActions.create_for_meta(
      msg, admin, meta.user, meta, true
    )

    Meta.mark_fixed(meta)
    |> Repo.update()
  end

  def mark_fixed(meta, admin, _), do: {:error, "#{admin.name} is not an admin"}

  ##
  # deletion

  def delete(meta), do: Repo.delete(meta)
end
