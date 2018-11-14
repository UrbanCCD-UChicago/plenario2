defmodule Plenario.SchemaUtils do
  alias Plenario.DataSetActions

  def slugify(value), do: SimpleSlug.slugify(value)

  def postgresify(value), do: SimpleSlug.slugify(value, joiner: "_")

  def validate_data_set_state(changeset, state \\ "new") do
    ds =
      Ecto.Changeset.get_field(changeset, :data_set_id)
      |> DataSetActions.get!()

    case ds.state == state do
      true -> changeset
      false -> Ecto.Changeset.add_error(changeset, :base, "cannot be created or edited once the parent data set's state is no longer \"new\"")
    end
  end
end
