defmodule Plenario.Repo.Migrations.AlterMetaRefreshDates do
  use Ecto.Migration

  def change do
    alter table(:metas) do
      modify :refresh_starts_on, :date
      modify :refresh_ends_on, :date
    end
  end
end
