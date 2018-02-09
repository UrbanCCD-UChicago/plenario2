defmodule PlenarioWeb.Web.Testing.UniqueConstraintControllerTest do
  use PlenarioWeb.Testing.ConnCase, async: true

  alias Plenario.Actions.{
    MetaActions,
    DataSetFieldActions,
    UniqueConstraintActions
  }

  setup %{reg_user: user} do
    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")
    {:ok, field} = DataSetFieldActions.create(meta, "name", "text")
    {:ok, field2} = DataSetFieldActions.create(meta, "name2", "text")
    {:ok, uc} = UniqueConstraintActions.create(meta, [field.id])

    {:ok, [meta: meta, field: field, field2: field2, uc: uc]}
  end

  @tag :auth
  test "new", %{conn: conn, meta: meta} do
    conn
    |> get(unique_constraint_path(conn, :new, meta.id))
    |> html_response(:ok)
  end

  describe "create" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta, field2: field} do
      params = %{
        "unique_constraint" => %{
          "meta_id" => meta.id,
          "field_ids" => [field.id]
        }
      }

      conn
      |> post(unique_constraint_path(conn, :create, meta.id, params))
      |> html_response(:found)
    end

    @tag :auth
    test "with bad inputs", %{conn: conn, meta: meta} do
      params = %{
        "unique_constraint" => %{
          "meta_id" => meta.id,
          "field_ids" => [123456789]
        }
      }

      conn
      |> post(unique_constraint_path(conn, :create, meta.id, params))
      |> html_response(:bad_request)
    end
  end

  @tag :auth
  test "edit", %{conn: conn, meta: meta, uc: uc} do
    conn
    |> get(unique_constraint_path(conn, :edit, meta.id, uc.id))
    |> html_response(:ok)
  end

  describe "update" do
    @tag :auth
    test "with good inputs", %{conn: conn, meta: meta, uc: uc, field2: field} do
      params = %{
        "unique_constraint" => %{
          "meta_id" => meta.id,
          "field_ids" => [field.id]
        }
      }

      conn
      |> put(unique_constraint_path(conn, :update, meta.id, uc.id, params))
      |> html_response(:found)

      uc = UniqueConstraintActions.get(uc.id)
      assert uc.field_ids == [field.id]
    end

    @tag :auth
    test "with bad inputs", %{conn: conn, meta: meta, uc: uc} do
      params = %{
        "unique_constraint" => %{
          "meta_id" => meta.id,
          "field_ids" => [123456789]
        }
      }

      conn
      |> put(unique_constraint_path(conn, :update, meta.id, uc.id, params))
      |> html_response(:bad_request)
    end
  end

  @tag :auth
  test "delete", %{conn: conn, meta: meta, uc: uc} do
    conn
    |> delete(unique_constraint_path(conn, :delete, meta.id, uc.id))
    |> html_response(:found)

    refute UniqueConstraintActions.get(uc.id)
  end
end
