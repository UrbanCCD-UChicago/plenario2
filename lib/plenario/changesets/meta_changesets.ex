defmodule Plenario.Changesets.MetaChangesets do
  @moduledoc """
  This module defines functions used to create Ecto Changesets for various
  states of the Meta schema.
  """

  import Ecto.Changeset

  alias Plenario.Schemas.Meta

  @typedoc """
  A verbose map of parameter types for :create/1
  """
  @type create_params :: %{
    name: String.t(),
    user_id: integer,
    source_url: String.t(),
    source_type: String.t()
  }

  @typedoc """
  A verbose map of paramaters for :update/2
  """
  @type update_params :: %{
    name: String.t(),
    source_url: String.t(),
    source_type: String.t(),
    description: String.t() | nil,
    attribution: String.t() | nil,
    refresh_rate: String.t() | nil,
    refresh_interval: integer | nil,
    refresh_starts_on: DateTime | nil,
    refresh_ends_on: DateTime | nil
  }

  @create_param_keys [:name, :user_id, :source_url, :source_type]

  @update_param_keys [
    :name, :source_url, :source_type, :description, :attribution,
    :refresh_rate, :refresh_interval, :refresh_starts_on, :refresh_ends_on
  ]

  @doc """
  Generates a changeset for creating a new Meta

  ## Examples

    empty_changeset_for_form =
      MetaChangesets.create(%{})

    result =
      MetaChangesets.create(%{what: "ever"})
      |> Repo.insert()
    case result do
      {:ok, meta} -> do_something(with: meta)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %Meta{}
    |> cast(params, @create_param_keys)
    |> validate_required(@create_param_keys)
    |> unique_constraint(:source_url)
    |> unique_constraint(:name)
    |> cast_assoc(:user)
    |> validate_source_type()
    |> set_slug()
    |> set_table_name()
  end

  @doc """
  Generates a changeset for updating a Meta's name, source url, source type,
  description, attrinution, refresh rate, refresh interval, refresh starts on,
  and/or refresh ends on. If you need to update other values of the meta, there
  are specialty changeset functions to handle those cases.

  ## Example

    result =
      MetaChangesets.update(meta, %{name: "a different name"})
      |> Repo.update()
    case result do
      {:ok, meta} -> do_something(with: meta)
      {:error, changeset} -> do_something_else(with: changeset)
    end
  """
  @spec update(meta :: Meta, params :: update_params) :: Ecto.Changeset.t()
  def update(meta, params) do
    meta
    |> cast(params, @update_param_keys)
    |> validate_required([:name, :source_url, :source_type])
    |> unique_constraint(:source_url)
    |> unique_constraint(:name)
    |> validate_source_type()
    |> validate_refresh_rate()
    |> validate_refresh_interval()
    |> validate_refresh_ends_on()
    |> set_slug()
  end

  @doc """
  Updates a Meta's user relation. If you need to update other values of the
  meta, there are specialty changeset functions to handle those cases.

  ## Example

    MetaChangesets.update_user(meta, someone_else)
  """
  @spec update_user(meta :: Meta, params :: %{user_id: integer}) :: Ecto.Changeset.t()
  def update_user(meta, params) do
    meta
    |> cast(params, [:user_id])
    |> validate_required(:user_id)
    |> cast_assoc(:user)
  end

  @doc """
  Updates a Meta's first import. If you need to update other values of the
  meta, there are specialty changeset functions to handle those cases.

  ## Example

    MetaChangesets.update_first_import(meta, %{first_import: DateTime.utc_now()})
  """
  @spec update_first_import(meta :: Meta, params :: %{first_import: DateTime.t()}) :: Ecto.Changeset.t()
  def update_first_import(meta, params) do
    meta
    |> cast(params, [:first_import])
  end

  @doc """
  Updates a Meta's latest import. If you need to update other values of the
  meta, there are specialty changeset functions to handle those cases.

  ## Example

    MetaChangesets.update_latest_import(meta, %{latest_import: DateTime.utc_now()})
  """
  @spec update_latest_import(meta :: Meta, params :: %{latest_import: DateTime.t()}) :: Ecto.Changeset.t()
  def update_latest_import(meta, params) do
    meta
    |> cast(params, [:latest_import])
  end

  @doc """
  Updates a Meta's bounding box. If you need to update other values of the
  meta, there are specialty changeset functions to handle those cases.

  ## Example

    MetaChangesets.update_bbox(meta, %{bbox: Geo.Polygon{...}})
  """
  @spec update_bbox(meta :: Meta, bbox :: Geo.Polygon) :: Ecto.Changeset.t()
  def update_bbox(meta, params) do
    meta
    |> cast(params, [:bbox])
  end

  def update_time_range(meta, params) do
    meta
    |> cast(params, [:time_range])
  end

  defp validate_source_type(changeset) do
    source_type = get_field(changeset, :source_type)
    case Enum.member?(Meta.get_source_type_values(), source_type) do
      true -> changeset
      false -> add_error(changeset, :source_type, "Not a valid source type")
    end
  end

  defp validate_refresh_rate(changeset) do
    refresh_rate = get_field(changeset, :refresh_rate)
    case Enum.member?(Meta.get_refresh_rate_values(), refresh_rate) do
      true -> changeset
      false -> add_error(changeset, :refresh_rate, "Not a valid refresh rate")
    end
  end

  defp validate_refresh_interval(changeset) do
    refresh_rate = get_field(changeset, :refresh_rate)
    refresh_interval = get_field(changeset, :refresh_interval)

    case refresh_rate do
      nil ->
        case refresh_interval do
          nil -> changeset
          _ -> add_error(changeset, :refresh_interval, "Refresh rate is null")
        end

      _ ->
        cond do
          !is_integer(refresh_interval) -> add_error(changeset, :refresh_interval, "Must be a positive integer")
          refresh_interval <= 0 -> add_error(changeset, :refresh_interval, "Must be a positive integer")
          true -> changeset
        end
    end
  end

  defp validate_refresh_ends_on(changeset) do
    refresh_starts_on = get_field(changeset, :refresh_starts_on)
    refresh_ends_on = get_field(changeset, :refresh_ends_on)

    case refresh_starts_on do
      nil ->
        case refresh_ends_on do
          nil -> changeset
          _ -> add_error(changeset, :refresh_ends_on, "Refresh starts on is null")
        end

      _ ->
        cond do
          refresh_ends_on == nil -> changeset
          Date.compare(refresh_ends_on, refresh_starts_on) === :gt -> changeset
          true -> add_error(changeset, :refresh_ends_on, "Refresh ends on must be later than refresh starts on")
        end
    end
  end

  defp set_slug(%Ecto.Changeset{valid?: true, changes: %{name: name}} = changeset) do
    slug = Slug.slugify(name)
    put_change(changeset, :slug, slug)
  end
  defp set_slug(changeset), do: changeset

  defp set_table_name(%Ecto.Changeset{valid?: true} = changeset) do
    nonce =
      :crypto.strong_rand_bytes(16)
      |> Base.url_encode64()
      |> binary_part(0, 16)
    name = "ds_#{nonce}"
    put_change(changeset, :table_name, name)
  end
  defp set_table_name(changeset), do: changeset
end
