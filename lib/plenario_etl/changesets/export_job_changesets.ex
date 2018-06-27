defmodule PlenarioEtl.Changesets.ExportJobChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  ExportJob structs.
  """

  import Ecto.Changeset

  alias Plenario.Actions.MetaActions

  alias PlenarioEtl.Schemas.ExportJob

  @typedoc """
  Verbose map of params for create
  """
  @type create_params :: %{
          query: String.t(),
          user_id: integer,
          meta_id: integer
        }

  @create_param_keys [:query, :user_id, :meta_id]

  @doc """
  Creates a changeset for inserting a new ExportJob into the database
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t()
  def create(params) do
    %ExportJob{}
    |> cast(params, @create_param_keys)
    |> validate_required(@create_param_keys)
    |> cast_assoc(:user)
    |> cast_assoc(:meta)
    |> set_export_path()
    |> set_export_ttl()
  end

  # Creates a path name for dumping the table contents to S3
  defp set_export_path(changeset) do
    table_name = MetaActions.get(get_field(changeset, :meta_id)).table_name
    bucket = Application.get_env(:plenario, :s3_export_bucket)
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    file_name = "#{bucket}/#{table_name}.#{now}.csv"

    changeset |> put_change(:export_path, file_name)
  end

  # Creates a TTL for the S3 exports so we're not paying to hold these things forever
  defp set_export_ttl(changeset) do
    now = DateTime.utc_now()
    delta = Application.get_env(:plenario, :s3_export_ttl)

    changeset |> put_change(:export_ttl, Timex.shift(now, delta))
  end
end
