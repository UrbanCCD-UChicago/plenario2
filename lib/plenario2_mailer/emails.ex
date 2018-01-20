defmodule Plenario2.Emails do
  import Bamboo.Email

  alias Plenario2.Schemas.AdminUserNote

  alias Plenario2Auth.UserActions

  defp base(), do: new_email(from: "plenario@uchicago.edu", subject: "Plenario Notification")

  @doc """
  Sends an AdminUserNote to the user
  """
  @spec compose_admin_user_note(note :: AdminUserNote) :: Bamboo.Email.t()
  def compose_admin_user_note(note) do
    user = UserActions.get_from_id(note.user_id)

    base()
    |> to(user.email_address)
  |> text_body(note.note)
  end
end
