defmodule PlenarioWeb.Web.AdminUserNoteController do
  use PlenarioWeb, :web_controller

  alias PlenarioMailer.Actions.AdminUserNoteActions

  def mark_acknowledged(conn, %{"id" => id, "redir" => redir}) do
    note = AdminUserNoteActions.get(id)
    AdminUserNoteActions.mark_acknowledged(note)
    redirect(conn, to: redir)
  end
end
