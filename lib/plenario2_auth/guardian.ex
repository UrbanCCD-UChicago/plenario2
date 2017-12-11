defmodule Plenario2Auth.Guardian do
  use Guardian, otp_app: :plenario2
  alias Plenario2Auth.UserActions

  def subject_for_token(user, _claims) do
    {:ok, user.id}
  end

  def resource_from_claims(claims) do
    user = _get_user(claims["sub"])
    case user do
      nil -> {:error, "Unknown user"}
      _   -> {:ok, user}
    end
  end

  defp _get_user(id) when is_integer(id), do: UserActions.get_from_id(id)
  defp _get_user(email), do: UserActions.get_from_email(email)
end
