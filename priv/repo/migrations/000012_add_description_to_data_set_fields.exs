defmodule Plenario.Repo.Migrations.AddDescriptionToDataSetFields do
  use Ecto.Migration

  def change do
    alter table("data_set_fields") do
      add :description, :text
    end
  end
end
