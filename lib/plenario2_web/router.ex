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
    get "/datasets/:slug/update/name", MetaController, :get_update_name
    put "/datasets/:slug/update/name", MetaController, :do_update_name
    get "/datasets/:slug/update/description", MetaController, :get_update_description
    put "/datasets/:slug/update/description", MetaController, :do_update_description
    get "/datasets/:slug/update/source", MetaController, :get_update_source_info
    put "/datasets/:slug/update/source", MetaController, :do_update_source_info
    get "/datasets/:slug/update/refresh", MetaController, :get_update_refresh_info
    put "/datasets/:slug/update/refresh", MetaController, :do_update_refresh_info
  end

  # Other scopes may use custom stacks.
  # scope "/api", Plenario2Web do
  #   pipe_through :api
  # end
end
