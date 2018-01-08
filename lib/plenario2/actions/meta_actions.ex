defmodule Plenario2.Actions.MetaActions do
  @moduledoc """
  This module provides a common API for the business logic
  underlying the various public interfaces for VirtualDateField.
  """

  import Plenario2.Guards, only: [is_id: 1]

  alias Plenario2Auth.User

  alias Plenario2.Changesets.MetaChangesets
  alias Plenario2.Queries.MetaQueries, as: Q
  alias Plenario2.Actions.AdminUserNoteActions
  alias Plenario2.Schemas.{Meta, DataSetConstraint}
  alias Plenario2.Repo

  @typedoc """
  Parameter is an ID attribute
  """
  @type id :: String.t | integer

  @typedoc """
  Parameter is a keyword list
  """
  @type kwlist :: list({atom, any})

  @typedoc """
  Returns a tuple of :ok, Meta or :error, Ecto.Changeset
  """
  @type ok_meta :: {:ok, Meta} | {:error, Ecto.Changeset.t}

  @doc """
  Gets an instance of a Meta by its ID or slug, optionally preloading
  relations and applying other filters
  """
  @spec get(id_or_slug :: id, opts :: kwlist) :: Meta
  def get(id_or_slug, opts \\ []) do
    case is_integer(id_or_slug) or Regex.match?(~r/^\d+$/, id_or_slug) do
      true -> get_by_id(id_or_slug, opts)
      false -> get_by_slug(id_or_slug, opts)
    end
  end

  defp get_by_id(id, opts) do
    Q.from_id(id)
    |> Q.handle_opts(opts)
    |> Repo.one()
  end

  defp get_by_slug(slug, opts) do
    Q.from_slug(slug)
    |> Q.handle_opts(opts)
    |> Repo.one()
  end

  @doc """
  Gets a list of Metas, optionally preloading relations
  and applying filters. See MetaQueries.handle_opts for more info
  """
  @spec list(opts :: kwlist) :: list(Meta)
  def list(opts \\ []) do
    Q.list()
    |> Q.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Lists all Metas that are owned by a given user, optionally preloading
  relations and applying filters. See MetaQueries.handle_opts for more info
  """
  @spec list_for_user(user :: User, opts :: kwlist) :: list(Meta)
  def list_for_user(user, opts \\ []) do
    local_defaults = [with_user: true, for_user: user]
    opts = Keyword.merge(local_defaults, opts)

    Q.list()
    |> Q.handle_opts(opts)
    |> Repo.all()
  end

  @doc """
  Creates a new instance of a Meta
  """
  @spec create(name :: String.t, user :: User | id, source_url :: String.t, details :: kwlist) :: ok_meta
  def create(name, user, source_url, details \\ []) do
    user_id =
      case is_id(user) do
        true -> user
        false -> user.id
      end

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

    MetaChangesets.create(params)
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

  @doc """
  Updates the name of the data set
  """
  @spec update_name(meta :: %Meta{}, new_name :: String.t) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def update_name(meta, new_name) do
    MetaChangesets.update_name(meta, %{name: new_name})
    |> Repo.update()
  end

  @doc """
  updates the user/owner of the data set
  """
  @spec update_user(meta :: %Meta{}, user :: %User{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def update_user(meta, user) do
    MetaChangesets.update_user(meta, %{user_id: user.id})
    |> Repo.update()
  end

  @doc """
  Updates the source_* fields of the Meta
  """
  @spec update_source_info(meta :: %Meta{}, options :: %{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
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

  @doc """
  Updates the descriptive fields of the meta
  """
  @spec update_description_info(meta :: %Meta{}, options :: %{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
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

  @doc """
  Updates the refresh_* fields of the Meta
  """
  @spec update_refresh_info(meta :: %Meta{}, options :: %{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
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

  # TODO: implement after setting up ds table and get rows
  # def update_bbox(meta), do: meta

  # TODO: implement after setting up ds table and get rows
  # def update_timerange(meta), do: meta

  @doc """
  Updates the next refresh field of the Meta
  """
  @spec update_next_refresh(meta :: %Meta{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
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

  @doc """
  Handles the state transition of the Meta from new to needing approval
  """
  @spec submit_for_approval(meta :: %Meta{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def submit_for_approval(meta) do
    Meta.submit_for_approval(meta)
    |> Repo.update()
  end

  @doc """
  Handles the state transition of the Meta from needing approval to ready
  """
  @spec approve(meta :: %Meta{}, admin :: %User{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def approve(meta, %User{is_admin: true} = admin) do
    AdminUserNoteActions.create_for_meta(
      "Your data set has been approved",
      admin, meta.user, meta, false
    )

    Meta.approve(meta)
    |> Repo.update()
  end

  def approve(_, admin), do: {:error, "#{admin.name} is not an admin"}

  @doc """
  Handles the state transition of the Meta from needing approval to new
  """
  @spec disapprove(meta :: %Meta{}, admin :: %User{}, message :: String.t) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def disapprove(meta, %User{is_admin: true} = admin, message) do
    msg = "Approval has been denied:\n\n" <> message
    AdminUserNoteActions.create_for_meta(
      msg, admin, meta.user, meta, true
    )

    Meta.disapprove(meta)
    |> Repo.update()
  end

  def disapprove(_, admin, _), do: {:error, "#{admin.name} is not an admin"}

  @doc """
  Handle the state transition of the Meta from whatever to erred
  """
  @spec mark_erred(meta :: %Meta{}, admin :: %User{}, message :: String.t) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def mark_erred(meta, %User{is_admin: true} = admin, message) do
    msg = "An error occurred regarding your data set:\n\n" <> message
    AdminUserNoteActions.create_for_meta(
      msg, admin, meta.user, meta, true
    )

    Meta.mark_erred(meta)
    |> Repo.update()
  end

  def mark_erred(_, admin, _), do: {:error, "#{admin.name} is not an admin"}

  @doc """
  Handle the state transition of the Meta from erred to ready
  """
  @spec mark_fixed(meta :: %Meta{}, admin :: %User{}, message :: String.t) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def mark_fixed(meta, %User{is_admin: true} = admin, message) do
    msg = "Data set error fixed:\n\n" <> message
    AdminUserNoteActions.create_for_meta(
      msg, admin, meta.user, meta, true
    )

    Meta.mark_fixed(meta)
    |> Repo.update()
  end

  def mark_fixed(_, admin, _), do: {:error, "#{admin.name} is not an admin"}

  @doc """
  Deletes a given Meta
  """
  @spec delete(meta :: %Meta{}) :: {:ok, %Meta{} | :error, Ecto.Changeset.t}
  def delete(meta), do: Repo.delete(meta)
end
