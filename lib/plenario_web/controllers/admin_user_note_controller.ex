defmodule PlenarioWeb.AdminUserNoteController do
  use PlenarioWeb, :controller

  alias PlenarioMailer.Actions.AdminUserNoteActions

  def acknowledge(conn, %{"id" => note_id, "path" => path}) do
    AdminUserNoteActions.get(note_id)
    |> AdminUserNoteActions.mark_acknowledged()

    redirect(conn, to: path)
  end
end
