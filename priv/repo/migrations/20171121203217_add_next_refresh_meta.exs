defmodule Plenario2.Repo.Migrations.AddNextRefreshMeta do
  use Ecto.Migration

  def change do
    alter table(:metas) do
      add :next_refresh, :timestamptz, default: nil
    end
  end
end
