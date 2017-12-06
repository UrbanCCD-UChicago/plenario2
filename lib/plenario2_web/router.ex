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

  # checks for a user in the session and if exists assigns to :current_user
  pipeline :authenticate do
    plug Plenario2Auth.AuthenticationPipeline
    plug Plenario2Auth.CurrentUserPlug
  end

  # ensures an authenticated user in the session
  pipeline :ensure_authenticated do
    plug Guardian.Plug.EnsureAuthenticated
    plug Plenario2Auth.CurrentUserPlug
  end

  pipeline :ensure_admin do
    plug Plenario2Auth.AdminPlug
  end

  scope "/", Plenario2Web do
    pipe_through [:browser, :authenticate]

    # generic paths
    get   "/",        PageController, :index

    # auth paths
    get   "/login",     AuthController, :get_login
    post  "/login",     AuthController, :do_login
    post  "/logout",    AuthController, :logout
    get   "/register",  AuthController, :get_register
    post  "/register",  AuthController, :do_register

    # meta paths
    get "/data-sets/list", MetaController, :list
    get "/data-sets/:slug/detail", MetaController, :detail
  end

  scope "/", Plenario2Web do
    pipe_through [:browser, :authenticate, :ensure_authenticated]

    # meta paths
    get "/data-sets/create", MetaController, :get_create
    post "/data-sets/create", MetaController, :do_create
    get "/data-sets/:slug/update/name", MetaController, :get_update_name
    put "/data-sets/:slug/update/name", MetaController, :do_update_name
    get "/data-sets/:slug/update/description", MetaController, :get_update_description
    put "/data-sets/:slug/update/description", MetaController, :do_update_description
    get "/data-sets/:slug/update/source", MetaController, :get_update_source_info
    put "/data-sets/:slug/update/source", MetaController, :do_update_source_info
    get "/data-sets/:slug/update/refresh", MetaController, :get_update_refresh_info
    put "/data-sets/:slug/update/refresh", MetaController, :do_update_refresh_info
    post "/data-sets/:slug/submit-for-approval", MetaController, :submit_for_approval

    resources "/data-sets/:slug/fields", DataSetFieldController

    post "/notes/:id/acknowledge", AdminUserNoteController, :acknowledge
  end

  scope "/admin", Plenario2Web do
    pipe_through [:browser, :authenticate, :ensure_authenticated, :ensure_admin]

    get "/", AdminController, :index

    get "/users", AdminController, :user_index
    put "/users/:user_id/activate", AdminController, :activate_user
    put "/users/:user_id/archive", AdminController, :archive_user
    put "/users/:user_id/trust", AdminController, :trust_user
    put "/users/:user_id/untrust", AdminController, :untrust_user
    put "/users/:user_id/promote-admin", AdminController, :promote_to_admin
    put "/users/:user_id/strip-admin", AdminController, :strip_admin_privs

    get "/metas", AdminController, :meta_index
    get "/metas/:id/approval-review", AdminController, :get_meta_approval_review
    post "/metas/:id/approve", AdminController, :approve_meta
    post "/metas/:id/disapprove", AdminController, :disapprove_meta
  end

  # Other scopes may use custom stacks.
  # scope "/api", Plenario2Web do
  #   pipe_through :api
  # end
end
