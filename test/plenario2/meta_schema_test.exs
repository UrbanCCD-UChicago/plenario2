defmodule MetaSchemaTests do
  use ExUnit.Case, async: true
  alias Plenario2.Actions.MetaActions
  alias Plenario2.Schemas.Meta
  alias Plenario2.Repo
  alias Plenario2Auth.UserActions

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "get data set table name" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    name = Meta.get_data_set_table_name(meta)
    assert name == "chicago_tree_trimming"
  end

  test "get data set table name with non-latin characters" do
    {:ok, user} = UserActions.create("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("進撃の巨人", user.id, "https://www.example.com/attack-on-titan")

    name = Meta.get_data_set_table_name(meta)
    assert name == "進撃の巨人"
  end
end
