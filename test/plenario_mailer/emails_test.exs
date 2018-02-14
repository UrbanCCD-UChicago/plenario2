defmodule PlenarioMailer.Testing.EmailsTest do
  use Plenario.Testing.DataCase, async: true

  alias PlenarioMailer.Emails

  alias PlenarioMailer.Actions.AdminUserNoteActions

  alias Plenario.Actions.UserActions

  setup context do
    user = context[:user]
    {:ok, _} = UserActions.promote_to_admin(user)
    context
  end

  test :compose_admin_user_note, context do
    {:ok, note} =
      AdminUserNoteActions.create_for_meta(
        context[:meta],
        context[:user],
        context[:user],
        "This is a test",
        false
      )

    email = Emails.compose_admin_user_note(note)
    assert email.from == "plenario@uchicago.edu"
    assert email.to == context.user.email
    assert email.subject == "Plenario Notification"
    assert email.text_body == "This is a test"
    assert email.html_body == nil
  end
end
