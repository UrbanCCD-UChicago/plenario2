defmodule Plenario2.Changesets.AdminUserNoteChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  AdminUserNote structs.
  """

  import Ecto.Changeset

  alias Plenario2.Schemas.AdminUserNote

  @typedoc """
  Verbose map of params for create_for_meta
  """
  @type create_meta_params :: %{
    note: String.t,
    should_email: boolean,
    admin_id: integer,
    user_id: integer,
    meta_id: integer
  }

  @new_create_meta_param_keys [:note, :should_email, :admin_id, :user_id, :meta_id]

  def new_for_meta() do
    %AdminUserNote{}
    |> cast(%{}, @new_create_meta_param_keys)
  end

  @doc """
  Creates a new AdminUserNote that is related to a Meta entity
  """
  @spec create_for_meta(params :: create_meta_params) :: Ecto.Changeset.t
  def create_for_meta(params) do
    %AdminUserNote{}
    |> cast(params, @new_create_meta_param_keys)
    |> validate_required([:note, :admin_id, :user_id, :meta_id])
    |> cast_assoc(:admin)
    |> cast_assoc(:user)
    |> cast_assoc(:meta)
  end

  # def create_for_etl_job(struct, params) do
  #   struct
  #   |> cast(params, [:note, :should_email, :admin_id, :user_id, :etl_job_id])
  #   |> validate_required([:note, :admin_id, :user_id, :etl_job_id])
  #   |> cast_assoc(:admin)
  #   |> cast_assoc(:user)
  #   |> cast_assoc(:etl_job)
  # end

  # def create_for_export_job(struct, params) do
  #   struct
  #   |> cast(params, [:note, :should_email, :admin_id, :user_id, :export_job_id])
  #   |> validate_required([:note, :admin_id, :user_id, :export_job_id])
  #   |> cast_assoc(:admin)
  #   |> cast_assoc(:user)
  #   |> cast_assoc(:export_job)
  # end

  @doc """
  Creates a changeset to update a given note's acknowledged bit in the database
  """
  @spec update_acknowledged(note :: AdminUserNote, params :: %{acknowledged: boolean}) :: Ecto.Changeset.t
  def update_acknowledged(note, params) do
    note
    |> cast(params, [:acknowledged])
    |> validate_required([:acknowledged])
  end
end
