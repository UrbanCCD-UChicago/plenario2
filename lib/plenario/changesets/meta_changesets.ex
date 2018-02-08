defmodule Plenario.Changesets.MetaChangesets do
  @moduledoc """
  This module defines functions used to create and update changesets for
  the Meta schema.
  """

  import Ecto.Changeset

  alias Plenario.Schemas.Meta

  @type create_params :: %{
    name: String.t(),
    source_url: String.t(),
    source_type: String.t(),
    user_id: integer
  }

  @type update_params :: %{
    name: String.t(),
    description: String.t() | nil,
    attribution: String.t() | nil,
    source_url: String.t() | nil,
    source_type: String.t() | nil,
    refresh_rate: String.t() | nil,
    refresh_interval: integer | nil,
    refresh_starts_on: Date | nil,
    refresh_ends_on: Date | nil,
    first_import: DateTime | nil,
    latest_import: DateTime | nil,
    next_import: DateTime | nil,
    bbox: Geo.Polygon | nil,
    time_range: Plenario.TsTzRange | Postgrex.Range | nil
  }

  @required_keys [:name, :source_url, :source_type, :user_id]

  @create_keys [:name, :source_url, :source_type, :user_id]

  @update_keys [
    :name, :description, :attribution, :source_url, :source_type, :refresh_rate,
    :refresh_interval, :refresh_starts_on, :refresh_ends_on, :first_import,
    :latest_import, :next_import, :bbox, :time_range
  ]

  @acceptible_post_new_update_keys MapSet.new([
    :first_import, :latest_import, :next_import, :bbox, :time_range
  ])

  @spec new() :: Ecto.Changeset.t()
  def new(), do: %Meta{} |> cast(%{}, @create_keys)

  @spec create(params :: create_params) :: Ecto.Changeset
  def create(params) do
    %Meta{}
    |> cast(params, @create_keys)
    |> validate_required(@required_keys)
    |> unique_constraint(:source_url)
    |> unique_constraint(:name)
    |> cast_assoc(:user)
    |> test_source_url()
    |> validate_source_type()
    |> set_slug()
    |> set_table_name()
  end

  @spec update(instance :: Meta, params :: update_params) :: Ecto.Changeset
  def update(instance, params) do
    instance
    |> cast(params, @update_keys)
    |> validate_required(@required_keys)
    |> unique_constraint(:source_url)
    |> unique_constraint(:name)
    |> cast_assoc(:user)
    |> validate_state()
    |> test_source_url()
    |> validate_source_type()
    |> validate_refresh_rate()
    |> validate_refresh_interval()
    |> validate_refresh_ends_on()
    |> set_slug()
  end

  defp validate_state(%Ecto.Changeset{valid?: true, changes: changes} = changeset) do
    case get_field(changeset, :state) do
      "new" -> changeset
      _ ->
        change_keys = MapSet.new(Map.keys(changes))
        case MapSet.size(MapSet.difference(change_keys, @acceptible_post_new_update_keys)) > 0 do
          false -> changeset
          true -> add_error(changeset, :base, "Cannot edit a data set once it's in process.")
        end
    end
  end
  defp validate_state(changeset), do: changeset

  defp test_source_url(%Ecto.Changeset{valid?: true, changes: %{source_url: source_url}} = changeset) do
    # try an OPTIONS request first
    case HTTPoison.options(source_url) do
      {:ok, response} ->
        if response.status_code == 200 do
          changeset
        else
          add_error(changeset, :source_url, "Could not find document at URL")
        end

      {:error, _} ->
        # then try a HEAD request
        case HTTPoison.head(source_url) do
          {:ok, response} ->
            if response.status_code == 200 do
              changeset
            else
              add_error(changeset, :source_url, "Could not find document at URL")
            end

          # if neither work then call it dead
          {:error, _} ->
            add_error(changeset, :source_url, "Could not connect to URL")
        end
    end
  end
  defp test_source_url(changeset), do: changeset

  defp validate_source_type(%Ecto.Changeset{valid?: true, changes: %{source_type: source_type}} = changeset) do
    case Enum.member?(Meta.get_source_type_values(), source_type) do
      true -> changeset
      false -> add_error(changeset, :source_type, "Not a valid source type")
    end
  end
  defp validate_source_type(changeset), do: changeset

  defp validate_refresh_rate(%Ecto.Changeset{valid?: true, changes: %{refresh_rate: refresh_rate}} = changeset) do
    case Enum.member?(Meta.get_refresh_rate_values(), refresh_rate) do
      true -> changeset
      false -> add_error(changeset, :refresh_rate, "Not a valid refresh rate")
    end
  end
  defp validate_refresh_rate(changeset), do: changeset

  defp validate_refresh_interval(%Ecto.Changeset{valid?: true} = changeset) do
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
          is_nil(refresh_interval) -> add_error(changeset, :refresh_interval, "Must be a positive integer")
          refresh_interval <= 0 -> add_error(changeset, :refresh_interval, "Must be a positive integer")
          true -> changeset
        end
    end
  end
  defp validate_refresh_interval(changeset), do: changeset

  defp validate_refresh_ends_on(%Ecto.Changeset{valid?: true, changes: %{refresh_ends_on: refresh_ends_on}} = changeset) do
    refresh_starts_on = get_field(changeset, :refresh_starts_on)

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
  defp validate_refresh_ends_on(changeset), do: changeset

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
