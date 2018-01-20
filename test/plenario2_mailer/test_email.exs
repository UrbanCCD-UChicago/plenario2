defmodule Plenario2.EmailsTest do
  use Plenario2.DataCase, async: true

  alias Plenario2.Emails

  alias Plenario2.Actions.AdminUserNoteActions

  alias Plenario2Auth.UserActions

  setup context do
    user = context[:user]
    {:ok, _} = UserActions.promote_to_admin(user)
    context
  end

  test :compose_admin_user_note, context do
    {:ok, note} = AdminUserNoteActions.create_for_meta(
      "This is a test", context[:user], context[:user], context[:meta], true)

    email = Emails.compose_admin_user_note(note)
    assert email.from == "plenario@uchicago.edu"
    assert email.to == context.user.email_address
    assert email.subject == "Plenario Notification"
    assert email.text_body == "This is a test"
    assert email.html_body == nil
  end
end
