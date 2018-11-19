defmodule Plenario.Auth.Guardian do
  use Guardian, otp_app: :plenario

  alias Plenario.{
    User,
    UserActions
  }

  def subject_for_token(%User{id: id}, _), do: {:ok, to_string(id)}

  def resource_from_claims(%{"sub" => id}) do
    case UserActions.get!(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end
end
