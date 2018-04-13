defmodule PlenarioMailer.Changesets.AdminUserNoteChangesets do
  @moduledoc """
  This module defines functions used to create and update changesets for
  the DataSetField schema.
  """

  import Ecto.Changeset

  alias PlenarioMailer.Schemas.AdminUserNote

  @type create_meta_params :: %{
    meta_id: integer,
    admin_id: integer,
    user_id: integer,
    message: String.t(),
    should_email: boolean
  }

  # @type create_etl_params :: %{
  #   etl_job_id: integer,
  #   admin_id: integer,
  #   user_id: integer,
  #   message: String.t(),
  #   should_email: boolean
  # }

  # @type create_export_params :: %{
  #   export_job_id: integer,
  #   admin_id: integer,
  #   user_id: integer,
  #   message: String.t(),
  #   should_email: boolean
  # }

  @create_meta_keys [:meta_id, :admin_id, :user_id, :message, :should_email]

  # @create_etl_keys [:etl_job_id, :admin_id, :user_id, :message, :should_email]

  # @create_export_keys [:export_job_id, :admin_id, :user_id, :message, :should_email]

  @spec new_for_meta() :: Ecto.Changeset.t()
  def new_for_meta(), do: %AdminUserNote{} |> cast(%{}, @create_meta_keys)

  # @spec new_for_etl() :: Ecto.Changeset.t()
  # def new_for_etl(), do: %AdminUserNote{} |> cast(%{}, @create_etl_keys)

  # @spec new_for_export() :: Ecto.Changeset.t()
  # def new_for_export(), do: %AdminUserNote{} |> cast(%{}, @create_export_keys)

  @spec create_for_meta(params :: create_meta_params) :: Ecto.Changeset.t()
  def create_for_meta(params) do
    %AdminUserNote{}
    |> cast(params, @create_meta_keys)
    |> validate_required(@create_meta_keys)
    |> cast_assoc(:meta)
    |> cast_assoc(:admin)
    |> cast_assoc(:user)
  end

  # @spec create_for_etl(params :: create_etl_params) :: Ecto.Changeset.t()
  # def create_for_etl(params) do
  #   %AdminUserNote{}
  #   |> cast(params, @create_etl_keys)
  #   |> validate_required(@create_etl_keys)
  #   |> cast_assoc(:etl_job)
  #   |> cast_assoc(:admin)
  #   |> cast_assoc(:user)
  # end

  # @spec create_for_export(params :: create_export_params) :: Ecto.Changeset.t()
  # def create_for_export(params) do
  #   %AdminUserNote{}
  #   |> cast(params, @create_export_keys)
  #   |> validate_required(@create_export_keys)
  #   |> cast_assoc(:export_job)
  #   |> cast_assoc(:admin)
  #   |> cast_assoc(:user)
  # end

  @spec update_acknowledged(instance :: AdminUserNote, params :: %{acknowleged: boolean}) :: Ecto.Changeset.t()
  def update_acknowledged(instance, params) do
    instance
    |> cast(params, [:acknowledged])
    |> validate_required([:acknowledged])
  end
end
