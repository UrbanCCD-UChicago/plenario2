defmodule VirtualPointFieldActionsTests do
  use ExUnit.Case, async: true
  alias Plenario2.Core.Actions.{VirtualPointFieldActions, MetaActions, UserActions}
  alias Plenario2.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  test "create virtual point field from long/lat" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = VirtualPointFieldActions.create_from_long_lat(meta.id, "longitude", "latitude")
    assert field.name == "_meta_point_longitude_latitude"
  end

  test "create virutal point field from location" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = VirtualPointFieldActions.create_from_loc(meta.id, "location")
    assert field.name == "_meta_point_location"
  end

  test "list virtual point fields for meta" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = VirtualPointFieldActions.create_from_loc(meta.id, "location")
    assert length(VirtualPointFieldActions.list_for_meta(meta)) == 1
  end

  test "delete virtual point field" do
    {:ok, user} = UserActions.create_user("Test User", "password", "test@example.com")
    {:ok, meta} = MetaActions.create("Chicago Tree Trimming", user.id, "https://www.example.com/chicago-tree-trimming")

    {:ok, field} = VirtualPointFieldActions.create_from_loc(meta.id, "location")
    assert length(VirtualPointFieldActions.list_for_meta(meta)) == 1

    VirtualPointFieldActions.delete(field)
    assert length(VirtualPointFieldActions.list_for_meta(meta)) == 0
  end
end
