defmodule Plenario.Repo.Migrations.CreateDataSetConstraints do
  use Ecto.Migration

  def change do
    create table(:data_set_constraints) do
      # constraint info
      add :field_names,     {:array, :text}
      add :constraint_name, :text

      # belongs to a meta entry
      add :meta_id, references(:metas)
    end

    create unique_index(:data_set_constraints, [:meta_id, :constraint_name])  # so meta
  end
end
