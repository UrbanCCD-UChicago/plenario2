defmodule Plenario2.Changesets.ExportJobChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  ExportJob structs.
  """

  import Ecto.Changeset

  alias Plenario2.Actions.MetaActions
  alias Plenario2.Schemas.ExportJob

  @doc """
  Creates a changeset for inserting a new ExportJob into the database
  """
  @spec create(struct :: %ExportJob{}, params :: %{}) :: Ecto.Changeset.t
  def create(struct, params) do
    struct
    |> cast(params, [:query, :include_diffs, :user_id, :meta_id])
    |> validate_required([:query, :include_diffs, :user_id, :meta_id])
    |> cast_assoc(:user)
    |> cast_assoc(:meta)
    |> set_export_path()
    |> set_diffs_path()
    |> set_export_ttl()
  end

  # Creates a path name for dumping the table contents to S3
  defp set_export_path(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get_from_id()
      |> MetaActions.get_data_set_table_name()

    bucket = Application.get_env(:plenario2, :s3_export_bucket)
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    file_name = "#{bucket}/#{table_name}.#{now}.csv"

    changeset |> put_change(:export_path, file_name)
  end

  # Creates a path name for dumping diffs to S3
  defp set_diffs_path(changeset) do
    if get_field(changeset, :include_diffs) == true do
      table_name =
        get_field(changeset, :meta_id)
        |> MetaActions.get_from_id()
        |> MetaActions.get_data_set_table_name()

      bucket = Application.get_env(:plenario2, :s3_export_bucket)
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      file_name = "#{bucket}/#{table_name}_diffs.#{now}.csv"
      changeset |> put_change(:diffs_path, file_name)
    else
      changeset |> put_change(:diffs_path, nil)
    end
  end

  # Creates a TTL for the S3 exports so we're not paying to hold these things forever
  defp set_export_ttl(changeset) do
    now = DateTime.utc_now()
    delta = Application.get_env(:plenario2, :s3_export_ttl)

    changeset |> put_change(:export_ttl, Timex.shift(now, delta))
  end
end
