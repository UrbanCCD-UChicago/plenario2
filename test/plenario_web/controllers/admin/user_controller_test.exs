defmodule PlenarioWeb.Admin.Testing.UserControllerTest do
  use PlenarioWeb.Testing.ConnCase

  alias Plenario.Actions.UserActions

  setup do
    {:ok, user} = UserActions.create("name", "email@example.com", "password")

    {:ok, [user: user]}
  end

  @tag :admin
  test "index", %{conn: conn} do
    response =
      conn
      |> get(user_path(conn, :index))
      |> html_response(:ok)

    UserActions.list()
    |> Enum.each(fn u -> assert response =~ u.name end)
  end

  @tag :admin
  test "edit", %{conn: conn, user: user} do
    conn
    |> get(user_path(conn, :edit, user.id))
    |> html_response(:ok)
  end

  @tag :admin
  test "update", %{conn: conn, user: user} do
    new_name = "some new name for the user"
    params = %{
      "user" => %{
        "name" => new_name,
        "email" => user.email,
        "bio" => user.bio
      }
    }

    conn
    |> put(user_path(conn, :update, user.id, params))
    |> html_response(:found)

    user = UserActions.get(user.id)
    assert user.name == new_name
  end

  @tag :admin
  test "strip admin privs", %{conn: conn, user: user} do
    {:ok, _} = UserActions.promote_to_admin(user)

    conn
    |> post(user_path(conn, :strip_admin_privs, user.id))
    |> html_response(:found)

    user = UserActions.get(user.id)
    refute user.is_admin
  end

  @tag :admin
  test "promote to admin", %{conn: conn, user: user} do
    conn
    |> post(user_path(conn, :promote_to_admin, user.id))
    |> html_response(:found)

    user = UserActions.get(user.id)
    assert user.is_admin
  end

  @tag :admin
  test "archive", %{conn: conn, user: user} do
    conn
    |> post(user_path(conn, :archive, user.id))
    |> html_response(:found)

    user = UserActions.get(user.id)
    refute user.is_active
  end

  @tag :admin
  test "activate", %{conn: conn, user: user} do
    {:ok, _} = UserActions.archive(user)

    conn
    |> post(user_path(conn, :activate, user.id))
    |> html_response(:found)

    user = UserActions.get(user.id)
    assert user.is_active
  end
end
