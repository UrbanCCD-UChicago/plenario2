defmodule Plenario2.Core.Changesets.ExportJobChangeset do
  import Ecto.Changeset
  alias Plenario2.Core.Actions.MetaActions

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
      |> MetaActions.get_meta_from_pk()
      |> MetaActions.get_dataset_table_name()

    bucket = Application.get_env(:plenario2, :s3_export_bucket)
    file_name = "#{bucket}/#{table_name}.csv"

    changeset |> put_change(:export_path, file_name)
  end

  defp _set_diffs_path(changeset) do
    table_name =
      get_field(changeset, :meta_id)
      |> MetaActions.get_meta_from_pk()
      |> MetaActions.get_dataset_table_name()

    bucket = Application.get_env(:plenario2, :s3_export_bucket)
    file_name = "#{bucket}/#{table_name}_diffs.csv"

    changeset |> put_change(:diffs_path, file_name)
  end

  defp _set_export_ttl(changeset) do
    now = :calendar.universal_now()
    delta = Application.get_env(:plenario2, :s3_export_ttl)

    changeset |> put_change(:export_ttl, Timex.shift(now, delta))
  end
end
