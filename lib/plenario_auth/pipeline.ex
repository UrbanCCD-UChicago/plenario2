defmodule PlenarioAuth.AuthenticationPipeline do
  @moduledoc """
  Defines the pipeline of Guardian plugs to be applied a request
  """

  use Guardian.Plug.Pipeline,
    otp_app: :plenario,
    error_handler: PlenarioAuth.ErrorHandler,
    module: PlenarioAuth.Guardian

  # if there's a session token, validate it
  plug(Guardian.Plug.VerifySession, claims: %{"typ" => "access"})

  # if there's a request header token, validate it
  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})

  # load the user if either token is valid
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
