defmodule Plenario2Auth.Guardian do
  @moduledoc """
  This defines the implementation for Guardian for the web application.
  When a user authenticates to the system, Guardian stores auth tokens in
  a session cookie and can associate already authenticated users' requests
  and pin the user to the request cycle.
  """

  use Guardian, otp_app: :plenario2

  alias Plenario2Auth.UserActions

  @doc """
  For a given known user, store their ID as their identifying value
  for the session.
  """
  def subject_for_token(user, _claims) do
    {:ok, user.id}
  end

  @doc """
  For a given user id, find the user entity in the database
  and pass the struct along for session usage.
  """
  def resource_from_claims(claims) do
    user = UserActions.get_from_id(claims["sub"])
    case user do
      nil -> {:error, "Unknown user"}
      _   -> {:ok, user}
    end
  end
end
