defmodule PlenarioAuth.Testing.AbilitiesTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest

  alias Plenario.Actions.{
    UserActions,
    MetaActions,
    DataSetFieldActions,
    VirtualDateFieldActions,
    VirtualPointFieldActions,
    UniqueConstraintActions
  }

  setup_all %{reg_user: user} do
    Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

    {:ok, meta} = MetaActions.create("name", user, "https://example.com/", "csv")
    {:ok, field} = DataSetFieldActions.create(meta, "name", "text")
    {:ok, vdf} = VirtualDateFieldActions.create(meta, field.id)
    {:ok, vpf} = VirtualPointFieldActions.create(meta, field.id)
    {:ok, uc} = UniqueConstraintActions.create(meta, [field.id])

    {:ok, [meta: meta, field: field, vdf: vdf, vpf: vpf, uc: uc]}
  end

  describe "anonymous user" do
    @tag :anon
    test "can access meta show", %{conn: conn, meta: meta} do
      conn
      |> get(data_set_path(conn, :show, meta.id))
      |> html_response(:ok)
    end

    @tag :anon
    test "are forbidden from all other meta actions", %{conn: conn, meta: meta} do
      conn
      |> get(data_set_path(conn, :edit, meta.id))
      |> response(:forbidden)
    end

    @tag :anon
    test "are forbidden from data set field actions", %{conn: conn, meta: meta, field: field} do
      conn
      |> get(data_set_field_path(conn, :edit, meta.id, field.id))
      |> response(:forbidden)
    end

    @tag :anon
    test "are forbidden from virtual date field actions", %{conn: conn, meta: meta, vdf: vdf} do
      conn
      |> get(virtual_date_path(conn, :edit, meta.id, vdf.id))
      |> response(:forbidden)
    end

    @tag :anon
    test "are forbidden from virtual point field actions", %{conn: conn, meta: meta, vpf: vpf} do
      conn
      |> get(virtual_point_path(conn, :edit, meta.id, vpf.id))
      |> response(:forbidden)
    end

    @tag :anon
    test "are forbidden from unique constraint actions", %{conn: conn, meta: meta, uc: uc} do
      conn
      |> get(unique_constraint_path(conn, :edit, meta.id, uc.id))
      |> response(:forbidden)
    end
  end

  describe "authenticated user who owns the parent meta" do
    @tag :auth
    test "can access all meta actions", %{conn: conn, meta: meta} do
      conn
      |> get(data_set_path(conn, :edit, meta.id))
      |> html_response(:ok)
    end

    @tag :auth
    test "can access all data set field actions", %{conn: conn, meta: meta, field: field} do
      conn
      |> get(data_set_field_path(conn, :edit, meta.id, field.id))
      |> html_response(:ok)
    end

    @tag :auth
    test "can access all virtual date field actions", %{conn: conn, meta: meta, vdf: vdf} do
      conn
      |> get(virtual_date_path(conn, :edit, meta.id, vdf.id))
      |> html_response(:ok)
    end

    @tag :auth
    test "can access all virtual point field actions", %{conn: conn, meta: meta, vpf: vpf} do
      conn
      |> get(virtual_point_path(conn, :edit, meta.id, vpf.id))
      |> html_response(:ok)
    end

    @tag :auth
    test "can access all unique constraint actions", %{conn: conn, meta: meta, uc: uc} do
      conn
      |> get(unique_constraint_path(conn, :edit, meta.id, uc.id))
      |> html_response(:ok)
    end
  end

  describe "authenticated user who doesn't own the parent meta" do
    setup do
      {:ok, user} = UserActions.create("new user", "email@example.com", "password")
      {:ok, meta} = MetaActions.create("another name", user, "https://example.com/1", "csv")
      {:ok, field} = DataSetFieldActions.create(meta, "name", "text")
      {:ok, vdf} = VirtualDateFieldActions.create(meta, field.id)
      {:ok, vpf} = VirtualPointFieldActions.create(meta, field.id)
      {:ok, uc} = UniqueConstraintActions.create(meta, [field.id])

      {:ok, [new_meta: meta, new_field: field, new_vdf: vdf, new_vpf: vpf, new_uc: uc]}
    end

    @tag :auth
    test "can access meta show", %{conn: conn, new_meta: meta} do
      conn
      |> get(data_set_path(conn, :show, meta.id))
      |> html_response(:ok)
    end

    @tag :auth
    test "are forbidden from all other meta actions", %{conn: conn, new_meta: meta} do
      conn
      |> get(data_set_path(conn, :edit, meta.id))
      |> response(:forbidden)
    end

    @tag :auth
    test "are forbidden from data set field action", %{conn: conn, new_meta: meta, new_field: field} do
      conn
      |> get(data_set_field_path(conn, :edit, meta.id, field.id))
      |> response(:forbidden)
    end

    @tag :auth
    test "are forbidden from virtual date field actions", %{conn: conn, new_meta: meta, new_vdf: vdf} do
      conn
      |> get(virtual_date_path(conn, :edit, meta.id, vdf.id))
      |> response(:forbidden)
    end

    @tag :auth
    test "are forbidden from virtual point field actions", %{conn: conn, new_meta: meta, new_vpf: vpf} do
      conn
      |> get(virtual_point_path(conn, :edit, meta.id, vpf.id))
      |> response(:forbidden)
    end

    @tag :auth
    test "are forbidden from unique constraint actions", %{conn: conn, new_meta: meta, new_uc: uc} do
      conn
      |> get(unique_constraint_path(conn, :edit, meta.id, uc.id))
      |> response(:forbidden)
    end
  end

  describe "admin users" do
    @tag :admin
    test "can access all meta actions", %{conn: conn, meta: meta} do
      conn
      |> get(data_set_path(conn, :edit, meta.id))
      |> html_response(:ok)
    end

    @tag :admin
    test "can access all data set field actions", %{conn: conn, meta: meta, field: field} do
      conn
      |> get(data_set_field_path(conn, :edit, meta.id, field.id))
      |> html_response(:ok)
    end

    @tag :admin
    test "can access all virtual date field actions", %{conn: conn, meta: meta, vdf: vdf} do
      conn
      |> get(virtual_date_path(conn, :edit, meta.id, vdf.id))
      |> html_response(:ok)
    end

    @tag :admin
    test "can access all virtual point field actions", %{conn: conn, meta: meta, vpf: vpf} do
      conn
      |> get(virtual_point_path(conn, :edit, meta.id, vpf.id))
      |> html_response(:ok)
    end

    @tag :admin
    test "can access all unique constraint actions", %{conn: conn, meta: meta, uc: uc} do
      conn
      |> get(unique_constraint_path(conn, :edit, meta.id, uc.id))
      |> html_response(:ok)
    end
  end
end
