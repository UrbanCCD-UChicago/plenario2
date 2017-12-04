defmodule Plenario2.Changesets.AdminUserNoteChangesets do
  import Ecto.Changeset

  def create_for_meta(struct, params) do
    struct
    |> cast(params, [:note, :should_email, :admin_id, :user_id, :meta_id])
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

  def update_acknowledged(note, params) do
    note
    |> cast(params, [:acknowledged])
    |> validate_required([:acknowledged])
  end
end
