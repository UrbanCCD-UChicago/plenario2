defmodule PlenarioWeb.UserController do
  use PlenarioWeb, :controller

  alias Plenario.Actions.{MetaActions, UserActions}
  alias Plenario.Changesets.UserChangesets

  alias PlenarioMailer.Actions.AdminUserNoteActions

  def index(conn, _) do
    user = Guardian.Plug.current_resource(conn)

    unread_notes = AdminUserNoteActions.list(unread: true, for_user: user)

    archived_notes =
      AdminUserNoteActions.list(acknowledged: true, for_user: user, oldest_first: true)

    new = MetaActions.list(for_user: user, new: true)
    awaiting = MetaActions.list(for_user: user, needs_approval: true)
    ready = MetaActions.list(for_user: user, ready: true, limit_to: 3)
    erred = MetaActions.list(for_user: user, erred: true)

    conn
    |> render(
      "index.html",
      unread_notes: unread_notes,
      archived_notes: archived_notes,
      new_metas: new,
      awaiting_metas: awaiting,
      ready_metas: ready,
      erred_metas: erred
    )
  end

  def get_update_name(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = UserActions.update(user)
    action = user_path(conn, :do_update_name)

    render(conn, "update_name.html", changeset: changeset, action: action)
  end

  def do_update_name(conn, %{"user" => %{"name" => name}}) do
    user = Guardian.Plug.current_resource(conn)

    UserActions.update(user, name: name)
    |> update_name_reply(conn)
  end

  defp update_name_reply({:ok, _}, conn) do
    conn
    |> put_flash(:success, "Your name has been updated")
    |> redirect(to: user_path(conn, :index))
  end

  defp update_name_reply({:error, changeset}, conn) do
    action = user_path(conn, :do_update_name)

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> put_status(:bad_request)
    |> render("update_name.html", changeset: changeset, action: action)
  end

  def get_update_email(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = UserActions.update(user)
    action = user_path(conn, :do_update_email)

    render(conn, "update_email.html", changeset: changeset, action: action)
  end

  def do_update_email(conn, %{"user" => %{"email_address" => email}}) do
    user = Guardian.Plug.current_resource(conn)

    UserActions.update(user, email: email)
    |> update_email_reply(conn)
  end

  defp update_email_reply({:ok, _}, conn) do
    conn
    |> put_flash(:success, "Your email address has been updated")
    |> redirect(to: user_path(conn, :index))
  end

  defp update_email_reply({:error, changeset}, conn) do
    action = user_path(conn, :do_update_email)

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> put_status(:bad_request)
    |> render("update_email.html", changeset: changeset, action: action)
  end

  def get_update_org_info(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = UserActions.update(user)
    action = user_path(conn, :do_update_org_info)

    render(conn, "update_org_info.html", changeset: changeset, action: action)
  end

  def do_update_org_info(conn, %{"user" => %{"bio" => bio}}) do
    user = Guardian.Plug.current_resource(conn)

    UserActions.update(user, bio: bio)
    |> update_org_info_reply(conn)
  end

  defp update_org_info_reply({:ok, _}, conn) do
    conn
    |> put_flash(:success, "Your organization information has been updated")
    |> redirect(to: user_path(conn, :index))
  end

  defp update_org_info_reply({:error, changeset}, conn) do
    action = user_path(conn, :do_update_org_info)

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> put_status(:bad_request)
    |> render("update_org_info.html", changeset: changeset, action: action)
  end

  def get_update_password(conn, _) do
    user = Guardian.Plug.current_resource(conn)
    changeset = UserChangesets.update_password(user, %{})
    action = user_path(conn, :do_update_password)

    render(conn, "update_password.html", changeset: changeset, action: action)
  end

  def do_update_password(conn, %{"user" => %{"plaintext_password" => password}}) do
    user = Guardian.Plug.current_resource(conn)

    UserActions.change_password(user, password)
    |> update_password_reply(conn)
  end

  defp update_password_reply({:ok, _}, conn) do
    conn
    |> put_flash(:success, "Your password has been updated")
    |> redirect(to: user_path(conn, :index))
  end

  defp update_password_reply({:error, changeset}, conn) do
    action = user_path(conn, :do_update_password)

    conn
    |> put_flash(:error, "Please review and fix errors below")
    |> put_status(:bad_request)
    |> render("update_password.html", changeset: changeset, action: action)
  end
end
