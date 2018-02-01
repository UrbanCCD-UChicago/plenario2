defmodule PlenarioMailer.Emails do
  import Bamboo.Email

  alias PlenarioMailer.Schemas.AdminUserNote

  alias Plenario.Actions.UserActions

  defp base() do
    new_email(
      from: Application.get_env(:plenario, :email_sender),
      subject: Application.get_env(:plenario, :email_subject)
    )
  end

  @doc """
  Sends an AdminUserNote to the user
  """
  @spec compose_admin_user_note(note :: AdminUserNote) :: Bamboo.Email.t()
  def compose_admin_user_note(note) do
    user = UserActions.get(note.user_id)

    base()
    |> to(user.email)
    |> text_body(note.message)
  end
end
