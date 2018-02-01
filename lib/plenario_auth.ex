defmodule PlenarioAuth do

  alias Plenario.Actions.UserActions

  @doc """
  From a given email and password pair, can a user be found in
  the database and do the password hashes match?
  """
  @spec authenticate(email :: String.t(), password :: String.t()) :: boolean
  def authenticate(email, password) do
    UserActions.get(email)
    |> check_password(password)
  end

  defp check_password(nil, _), do: {:error, "Incorrect email or password"}

  defp check_password(user, password) do
    case Comeonin.Bcrypt.checkpw(password, user.hashed_password) do
      true -> {:ok, user}
      false -> {:error, "Incorrect email or password"}
    end
end
end
