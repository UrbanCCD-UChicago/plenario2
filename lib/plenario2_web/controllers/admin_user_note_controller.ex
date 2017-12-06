defmodule Plenario2Web.AdminUserNoteController do
  use Plenario2Web, :controller

  alias Plenario2.Actions.AdminUserNoteActions

  def acknowledge(conn, %{"id" => note_id, "path" => path}) do
    AdminUserNoteActions.get_from_id(note_id)
    |> AdminUserNoteActions.mark_acknowledged()

    redirect(conn, to: path)
  end
end
