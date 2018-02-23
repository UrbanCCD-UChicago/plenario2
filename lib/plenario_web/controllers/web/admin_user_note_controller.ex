defmodule PlenarioWeb.Web.AdminUserNoteController do
  use PlenarioWeb, :web_controller

  alias PlenarioMailer.Actions.AdminUserNoteActions

  alias PlenarioMailer.Schemas.AdminUserNote

  def mark_acknowledged(conn, %{"id" => id, "redir" => redir}) do
    note = AdminUserNoteActions.get(id)
    do_mark_acknowledged(note, redir, conn)
  end

  defp do_mark_acknowledged(nil, _, conn), do: do_404(conn)
  defp do_mark_acknowledged(%AdminUserNote{} = note , redir, conn) do
    AdminUserNoteActions.mark_acknowledged(note)
    redirect(conn, to: redir)
  end
end
