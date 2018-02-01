defmodule Plenario.Repo.Migrations.CreateUniqueConstraints do
  use Ecto.Migration

  def change do
    create table(:unique_constraints) do
      add :meta_id, references(:metas), null: false
      add :field_ids, {:array, :integer}, null: false
      add :name, :text, null: false

      timestamps(type: :timestamptz)
    end

    create unique_index(:unique_constraints, [:meta_id, :field_ids])
  end
end
