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
    plug Plenario2Auth.CurrentUserPlug
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
    plug Plenario2Auth.CurrentUserPlug
  end

  scope "/", Plenario2Web do
    pipe_through [:browser, :auth]

    # generic paths
    get   "/",        PageController, :index

    # auth paths
    get   "/login",     AuthController, :get_login
    post  "/login",     AuthController, :do_login
    post  "/logout",    AuthController, :logout
    get   "/register",  AuthController, :get_register
    post  "/register",  AuthController, :do_register

    # meta paths
    get "/datasets/list", MetaController, :list
    get "/datasets/:slug/detail", MetaController, :detail
  end

  scope "/", Plenario2Web do
    pipe_through [:browser, :auth, :ensure_auth]

    # meta paths
    get "/datasets/create", MetaController, :get_create
    post "/datasets/create", MetaController, :do_create
  end

  # Other scopes may use custom stacks.
  # scope "/api", Plenario2Web do
  #   pipe_through :api
  # end
end
