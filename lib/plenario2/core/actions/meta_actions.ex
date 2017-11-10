defmodule Plenario2.Core.Actions.MetaActions do
  import Ecto.Query
  alias Plenario2.Core.Schemas.Meta
  alias Plenario2.Repo

  def get_meta_from_pk(pk), do: Repo.one(from m in Meta, where: m.id == ^pk)

  def get_dataset_table_name(meta) do
    meta.name
    |> String.split(~r/\s/, trim: true)
    |> Enum.map(&(String.downcase(&1)))
    |> Enum.join("_")
  end
end
