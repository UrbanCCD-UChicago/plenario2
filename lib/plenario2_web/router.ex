defmodule Plenario2Web.Router do
  use Plenario2Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth do
    plug Plenario2Auth.Pipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", Plenario2Web do
    # Use the default browser stack
    pipe_through [:browser, :auth]

    get("/", PageController, :index)
    post("/", PageController, :login)
    post("/logout", PageController, :logout)
  end

  scope "/", Plenario2Web do
    pipe_through [:browser, :auth, :ensure_auth]

    get "/secret", PageController, :secret
  end

  # Other scopes may use custom stacks.
  # scope "/api", Plenario2Web do
  #   pipe_through :api
  # end
end
