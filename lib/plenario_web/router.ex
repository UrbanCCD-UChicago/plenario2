defmodule PlenarioWeb.Router do
  use PlenarioWeb, :router

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
    plug(PlenarioAuth.AuthenticationPipeline)
    plug(PlenarioAuth.CurrentUserPlug)
  end

  # ensures an authenticated user in the session
  pipeline :ensure_authenticated do
    plug(Guardian.Plug.EnsureAuthenticated)
    plug(PlenarioAuth.CurrentUserPlug)
  end

  pipeline :ensure_admin do
    plug(PlenarioAuth.AdminPlug)
  end

  scope "/", PlenarioWeb do
    pipe_through([:browser, :authenticate])

    # generic paths
    get("/", PageController, :index)

    # auth paths
    get("/login", AuthController, :get_login)
    post("/login", AuthController, :do_login)
    post("/logout", AuthController, :logout)
    get("/register", AuthController, :get_register)
    post("/register", AuthController, :do_register)

    # meta paths
    get("/data-sets/list", MetaController, :list)
    get("/data-sets/:slug/detail", MetaController, :detail)
  end

  scope "/", PlenarioWeb do
    pipe_through([:browser, :authenticate, :ensure_authenticated])

    # meta paths
    get("/data-sets/create", MetaController, :get_create)
    post("/data-sets/create", MetaController, :do_create)
    get("/data-sets/:slug/update/name", MetaController, :get_update_name)
    put("/data-sets/:slug/update/name", MetaController, :do_update_name)
    get("/data-sets/:slug/update/description", MetaController, :get_update_description)
    put("/data-sets/:slug/update/description", MetaController, :do_update_description)
    get("/data-sets/:slug/update/source", MetaController, :get_update_source_info)
    put("/data-sets/:slug/update/source", MetaController, :do_update_source_info)
    get("/data-sets/:slug/update/refresh", MetaController, :get_update_refresh_info)
    put("/data-sets/:slug/update/refresh", MetaController, :do_update_refresh_info)
    post("/data-sets/:slug/submit-for-approval", MetaController, :submit_for_approval)
    post("/data-sets/:slug/ingest-dataset", MetaController, :ingest_dataset)

    resources("/data-sets/:slug/fields", DataSetFieldController)

    get(
      "/data-sets/:slug/virtual-points/create-loc",
      VirtualPointFieldController,
      :get_create_loc
    )

    post(
      "/data-sets/:slug/virtual-points/create-loc",
      VirtualPointFieldController,
      :do_create_loc
    )

    get(
      "/data-sets/:slug/virtual-points/create-longlat",
      VirtualPointFieldController,
      :get_create_longlat
    )

    post(
      "/data-sets/:slug/virtual-points/create-longlat",
      VirtualPointFieldController,
      :do_create_longlat
    )

    get("/data-sets/:slug/virtual-dates/create", VirtualDateFieldController, :get_create)
    post("/data-sets/:slug/virtual-dates/create", VirtualDateFieldController, :do_create)
    get("/data-sets/:slug/virtual-dates/:id/edit", VirtualDateFieldController, :edit)
    put("/data-sets/:slug/virtual-dates/:id/edit", VirtualDateFieldController, :update)

    get("/data-sets/:slug/constraints/create", DataSetConstraintController, :get_create)
    post("/data-sets/:slug/constraints/create", DataSetConstraintController, :do_create)
    get("/data-sets/:slug/constraints/:id/edit", DataSetConstraintController, :edit)
    put("/data-sets/:slug/constraints/:id/edit", DataSetConstraintController, :update)

    post("/notes/:id/acknowledge", AdminUserNoteController, :acknowledge)

    get("/my/info", UserController, :index)
    get("/my/name", UserController, :get_update_name)
    put("/my/name", UserController, :do_update_name)
    get("/my/email", UserController, :get_update_email)
    put("/my/email", UserController, :do_update_email)
    get("/my/org-info", UserController, :get_update_org_info)
    put("/my/org-info", UserController, :do_update_org_info)
    get("/my/password", UserController, :get_update_password)
    put("/my/password", UserController, :do_update_password)
  end

  scope "/admin", PlenarioWeb do
    pipe_through([:browser, :authenticate, :ensure_authenticated, :ensure_admin])

    get("/", AdminController, :index)

    get("/users", AdminController, :user_index)
    put("/users/:user_id/activate", AdminController, :activate_user)
    put("/users/:user_id/archive", AdminController, :archive_user)
    put("/users/:user_id/trust", AdminController, :trust_user)
    put("/users/:user_id/untrust", AdminController, :untrust_user)
    put("/users/:user_id/promote-admin", AdminController, :promote_to_admin)
    put("/users/:user_id/strip-admin", AdminController, :strip_admin_privs)

    get("/metas", AdminController, :meta_index)
    get("/metas/:id/approval-review", AdminController, :get_meta_approval_review)
    post("/metas/:id/approve", AdminController, :approve_meta)
    post("/metas/:id/disapprove", AdminController, :disapprove_meta)
  end

  # Other scopes may use custom stacks.
  # scope "/api", PlenarioWeb do
  #   pipe_through :api
  # end
end
