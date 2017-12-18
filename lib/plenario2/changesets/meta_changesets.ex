defmodule Plenario2.Changesets.MetaChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  Meta structs.
  """

  import Ecto.Changeset

  alias Plenario2.Tokens
  alias Plenario2.Schemas.Meta

  @doc """
  Creates a changeset for inserting a new Meta into the database.

  Params include:

    - name (required)
    - user_id (required)
    - source_url (required)
    - source_type
    - description
    - attribution
    - refresh_rate
    - refresh_interval
    - refresh_starts_on
    - refresh_ends_on
    - srid
    - timezone
  """
  @spec create(struct :: %Meta{}, params :: %{}) :: Ecto.Changeset.t
  def create(struct, params) do
    struct
    |> cast(params, [
         :name,
         :user_id,
         :description,
         :attribution,
         :source_url,
         :source_type,
         :refresh_rate,
         :refresh_interval,
         :refresh_starts_on,
         :refresh_ends_on,
         :srid,
         :timezone
       ])
    |> validate_required([:name, :user_id, :source_url, :source_type])
    |> cast_assoc(:user)
    |> unique_constraint(:name)
    |> unique_constraint(:source_url)
    |> set_slug()
    |> validate_refresh_rate()
    |> validate_refresh_interval()
    |> validate_refresh_ends_on()
    |> validate_source_type()
    |> put_change(:state, "new")
  end

  @doc """
  Creates a changeset for updating a Meta's name
  """
  @spec update_name(meta :: %Meta{}, params :: %{name: String.t}) :: Ecto.Changeset.t
  def update_name(meta, params) do
    meta
    |> cast(params, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @doc """
  Creates a changeset for updating a Meta's user reference
  """
  @spec update_user(meta :: %Meta{}, params :: %{user_id: integer}) :: Ecto.Changeset.t
  def update_user(meta, params) do
    meta
    |> cast(params, [:user_id])
    |> validate_required([:user_id])
    |> cast_assoc(:user)
  end

  @doc """
  Creates a changeset for updating a Meta's source information
  """
  @spec update_source_info(meta :: %Meta{}, params :: %{source_url: String.t, source_type: String.t}) :: Ecto.Changeset.t
  def update_source_info(meta, params) do
    meta
    |> cast(params, [:source_url, :source_type])
    |> validate_required([:source_url, :source_type])
    |> unique_constraint(:source_url)
    |> validate_source_type()
  end

  @doc """
  Creates a changeset for updating a Meta's descriptive fields
  """
  @spec update_description_info(meta :: %Meta{}, params :: %{description: String.t, attribution: String.t}) :: Ecto.Changeset.t
  def update_description_info(meta, params) do
    meta
    |> cast(params, [:description, :attribution])
  end

  @doc """
  Creates a changeset for updating a Meta's refresh information.

  Params include:

    - refresh_rate
    - refresh_interval
    - refresh_starts_on
    - refresh_ends_on
  """
  @spec update_refresh_info(meta :: %Meta{}, params :: %{}) :: Ecto.Changeset.t
  def update_refresh_info(meta, params) do
    meta
    |> cast(params, [:refresh_rate, :refresh_interval, :refresh_starts_on, :refresh_ends_on])
    |> validate_refresh_rate()
    |> validate_refresh_interval()
    |> validate_refresh_ends_on()
  end

#  def update_bbox(meta, params) do
#    meta
#    |> cast(params, [:bbox])
#  end

#  def update_timerange(meta, params) do
#    meta
#    |> cast(params, [:timerange])
#  end

  @doc """
  Creates a changeset for updating a Meta's next refresh field. This is intended to
  only be called by automated internal processes, mostly run after an EtlJob.
  """
  @spec update_next_refresh(meta :: %Meta{}, params :: %{next_refresh: %DateTime{}}) :: Ecto.Changeset.t
  def update_next_refresh(meta, params) do
    meta
    |> cast(params, [:next_refresh])
  end

  # Sets the slug for the meta entry
  defp set_slug(changeset), do: changeset |> put_change(:slug, Tokens.generate_token())


  # TODO: create some module level attribute for these values
  defp validate_refresh_rate(changeset) do
    rr = get_field(changeset, :refresh_rate)

    if Enum.member?([nil, "minutes", "hours", "days", "weeks", "months", "years"], rr) do
      changeset
    else
      changeset |> add_error(:refresh_rate, "Invalid value `#{rr}`")
    end
  end

  defp validate_refresh_interval(changeset) do
    rr = get_field(changeset, :refresh_rate)

    if rr == nil do
      changeset |> put_change(:refresh_interval, nil)
    else
      changeset
    end
  end

  defp validate_refresh_ends_on(changeset) do
    rso = get_field(changeset, :refresh_starts_on)

    if rso == nil do
      changeset |> put_change(:refresh_ends_on, nil)
    else
      reo = get_field(changeset, :refresh_ends_on)

      if reo > rso or reo == nil do
        changeset
      else
        changeset |> add_error(:refresh_ends_on, "Invalid: end date cannot precede start date")
      end
    end
  end

  # TODO: these values should be a module level attribute
  defp validate_source_type(changeset) do
    st = get_field(changeset, :source_type)

    if Enum.member?(["csv", "tsv", "shp", "json"], st) do
      changeset
    else
      changeset |> add_error(:source_type, "Invalid type `#{st}`")
    end
  end
end
