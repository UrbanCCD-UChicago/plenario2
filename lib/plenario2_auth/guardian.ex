defmodule Plenario2Auth.Guardian do
  use Guardian, otp_app: :plenario2
  alias Plenario2Auth.UserActions

  def subject_for_token(user, _claims) do
    {:ok, user.id}
  end

  def resource_from_claims(claims) do
    user = UserActions.get_from_email(claims["sub"])
    case user do
      nil -> {:error, "Unknown user"}
      _   -> {:ok, user}
    end
  end
end
