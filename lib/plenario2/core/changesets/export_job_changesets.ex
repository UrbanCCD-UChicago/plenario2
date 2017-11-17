defmodule Plenario2.Core.Changesets.ExportJobChangesets do
  import Ecto.Changeset
  alias Plenario2.Core.Actions.MetaActions
  alias Plenario2.Core.Schemas.Meta

  def create(struct, params) do
    struct
    |> cast(params, [:query, :include_diffs, :user_id, :meta_id])
    |> validate_required([:query, :include_diffs, :user_id, :meta_id])
    |> cast_assoc(:user)
    |> cast_assoc(:meta)
    |> _set_export_path()
    |> _set_diffs_path()
    |> _set_export_ttl()
  end

  ##
  # operations

  defp _set_export_path(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get_from_pk()
      |> Meta.get_dataset_table_name()

    bucket = Application.get_env(:plenario2, :s3_export_bucket)
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    file_name = "#{bucket}/#{table_name}.#{now}.csv"

    changeset |> put_change(:export_path, file_name)
  end

  defp _set_diffs_path(changeset) do
    if get_field(changeset, :include_diffs) == true do
      table_name =
        get_field(changeset, :meta_id)
        |> MetaActions.get_from_pk()
        |> Meta.get_dataset_table_name()

      bucket = Application.get_env(:plenario2, :s3_export_bucket)
      now = DateTime.utc_now() |> DateTime.to_iso8601()
      file_name = "#{bucket}/#{table_name}_diffs.#{now}.csv"
      changeset |> put_change(:diffs_path, file_name)
    else
      changeset |> put_change(:diffs_path, nil)
    end
  end

  defp _set_export_ttl(changeset) do
    now = DateTime.utc_now()
    delta = Application.get_env(:plenario2, :s3_export_ttl)

    changeset |> put_change(:export_ttl, Timex.shift(now, delta))
  end
end
