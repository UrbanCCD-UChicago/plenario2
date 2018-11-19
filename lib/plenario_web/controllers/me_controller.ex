defmodule PlenarioWeb.MeController do
  use PlenarioWeb, :controller

  import Ecto.Query

  alias Plenario.{
    DataSet,
    Repo,
    User,
    UserActions
  }

  def show(conn, _) do
    # fetch user and their data sets
    user = conn.assigns[:current_user]
    data_sets = Repo.all(from d in DataSet, where: d.user_id == ^user.id)

    # filter data sets
    erred = Enum.filter(data_sets, & &1.state == "erred")
    new = Enum.filter(data_sets, & &1.state == "new")
    approval = Enum.filter(data_sets, & &1.state == "awaiting_approval")
    first_import = Enum.filter(data_sets, & &1.state == "awaiting_first_import")
    ready = Enum.filter(data_sets, & &1.state == "ready")

    # actions
    edit_action = Routes.me_path(conn, :edit)

    render conn, "show.html",
      user: user,
      erred: erred,
      new: new,
      needs_approval: approval,
      awaiting_first_import: first_import,
      ready: ready,
      edit_action: edit_action
  end

  def edit(conn, _) do
    # fetch user
    user = conn.assigns[:current_user]

    # make changeset
    changeset = User.changeset(user, %{})

    # actions
    show_action = Routes.me_path(conn, :show)
    update_action = Routes.me_path(conn, :update)

    render conn, "edit.html",
      user: user,
      changeset: changeset,
      show_action: show_action,
      update_action: update_action
  end

  def update(conn, %{"user" => form}) do
    # fetch user
    user = conn.assigns[:current_user]

    # make changes
    UserActions.update(user, form)
    |> do_update(conn, user)
  end

  defp do_update({:ok, _}, conn, _) do
    conn
    |> put_flash(:success, "Successfully updated!")
    |> redirect(to: Routes.me_path(conn, :show))
  end

  defp do_update({:error, changeset}, conn, user) do
    # actions
    show_action = Routes.me_path(conn, :show)
    update_action = Routes.me_path(conn, :update)

    conn
    |> put_status(:bad_request)
    |> put_error_flashes(changeset)
    |> render("edit.html",
      user: user,
      changeset: changeset,
      show_action: show_action,
      update_action: update_action)
  end
end
