defmodule PlenarioWeb.Router do
  use PlenarioWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :maybe_authenticated do
    plug PlenarioAuth.AuthenticationPipeline
    plug PlenarioAuth.CurrentUserPlug
  end

  pipeline :ensure_authenticated do
    plug PlenarioAuth.AuthenticationPipeline
    plug Guardian.Plug.EnsureAuthenticated
    plug PlenarioAuth.CurrentUserPlug
  end

  pipeline :ensure_admin do
    plug PlenarioAuth.AuthenticationPipeline
    plug Guardian.Plug.EnsureAuthenticated
    plug PlenarioAuth.CurrentUserPlug
    plug PlenarioAuth.AdminPlug
  end

  ##
  # public web paths
  scope "/", PlenarioWeb.Web do
    pipe_through [:browser, :maybe_authenticated]

    # landing pages
    get "/", PageController, :index
    get "/explore", PageController, :explorer
    get "/explore/array-of-things", PageController, :aot_explorer

    # auth pages
    get "/login", AuthController, :index
    post "/login", AuthController, :login
    post "/register", AuthController, :register
    post "/logout", AuthController, :logout

    # user pages
    get "/me", MeController, :index
    get "/me/edit", MeController, :edit
    put "/me/update", MeController, :update
    get "/me/change-password", MeController, :edit_password
    put "/me/change-password", MeController, :update_password

    resources "/data-sets", DataSetController
    post "/data-sets/:id/submit-for-approval", DataSetController, :submit_for_approval
    post "/data-sets/:id/ingest-now", DataSetController, :ingest_now

    resources "/data-sets/:dsid/fields", DataSetFieldController
    resources "/data-sets/:dsid/constraints", UniqueConstraintController
    resources "/data-sets/:dsid/virtual-dates", VirtualDateController
    resources "/data-sets/:dsid/virtual-points", VirtualPointController
  end

  ##
  # admin paths
  scope "/admin", PlenarioWeb.Admin do
    pipe_through [:browser, :ensure_admin]

    get "/", AdminPageController, :index

    resources "/users", UserController
    post "/users/:id/promote-to-admin", UserController, :promote_to_admin
    post "/users/:id/strip-admin-privs", UserController, :strip_admin_privs
    post "/users/:id/activate", UserController, :activate
    post "/users/:id/archive", UserController, :archive

    resources "/metas", MetaController
    get "/metas/:id/review", MetaController, :review
    post "/metas/:id/approve", MetaController, :approve
    post "/metas/:id/disapprove", MetaController, :disapprove
  end

  ##
  # api paths
  scope "/api", PlenarioWeb.Api do
    pipe_through [:api]
  end
end



#
#   scope "/", PlenarioWeb do
#     pipe_through([:browser, :authenticate])
#
#     # generic paths
#     get("/", PageController, :index)
#
#     # auth paths
#     get("/login", AuthController, :get_login)
#     post("/login", AuthController, :do_login)
#     post("/logout", AuthController, :logout)
#     get("/register", AuthController, :get_register)
#     post("/register", AuthController, :do_register)
#
#     # meta paths
#     get("/data-sets/list", MetaController, :list)
#     get("/data-sets/:slug/detail", MetaController, :detail)
#   end
#
#   scope "/", PlenarioWeb do
#     pipe_through([:browser, :authenticate, :ensure_authenticated])
#
#     # meta paths
#     get("/data-sets/create", MetaController, :get_create)
#     post("/data-sets/create", MetaController, :do_create)
#     get("/data-sets/:slug/update/name", MetaController, :get_update_name)
#     put("/data-sets/:slug/update/name", MetaController, :do_update_name)
#     get("/data-sets/:slug/update/description", MetaController, :get_update_description)
#     put("/data-sets/:slug/update/description", MetaController, :do_update_description)
#     get("/data-sets/:slug/update/source", MetaController, :get_update_source_info)
#     put("/data-sets/:slug/update/source", MetaController, :do_update_source_info)
#     get("/data-sets/:slug/update/refresh", MetaController, :get_update_refresh_info)
#     put("/data-sets/:slug/update/refresh", MetaController, :do_update_refresh_info)
#     post("/data-sets/:slug/submit-for-approval", MetaController, :submit_for_approval)
#     post("/data-sets/:slug/ingest-dataset", MetaController, :ingest_dataset)
#
#     resources("/data-sets/:slug/fields", DataSetFieldController)
#
#     get(
#       "/data-sets/:slug/virtual-points/create-loc",
#       VirtualPointFieldController,
#       :get_create_loc
#     )
#
#     post(
#       "/data-sets/:slug/virtual-points/create-loc",
#       VirtualPointFieldController,
#       :do_create_loc
#     )
#
#     get(
#       "/data-sets/:slug/virtual-points/create-longlat",
#       VirtualPointFieldController,
#       :get_create_longlat
#     )
#
#     post(
#       "/data-sets/:slug/virtual-points/create-longlat",
#       VirtualPointFieldController,
#       :do_create_longlat
#     )
#
#     get("/data-sets/:slug/virtual-dates/create", VirtualDateFieldController, :get_create)
#     post("/data-sets/:slug/virtual-dates/create", VirtualDateFieldController, :do_create)
#     get("/data-sets/:slug/virtual-dates/:id/edit", VirtualDateFieldController, :edit)
#     put("/data-sets/:slug/virtual-dates/:id/edit", VirtualDateFieldController, :update)
#
#     get("/data-sets/:slug/constraints/create", DataSetConstraintController, :get_create)
#     post("/data-sets/:slug/constraints/create", DataSetConstraintController, :do_create)
#     get("/data-sets/:slug/constraints/:id/edit", DataSetConstraintController, :edit)
#     put("/data-sets/:slug/constraints/:id/edit", DataSetConstraintController, :update)
#
#     post("/notes/:id/acknowledge", AdminUserNoteController, :acknowledge)
#
#     get("/my/info", UserController, :index)
#     get("/my/name", UserController, :get_update_name)
#     put("/my/name", UserController, :do_update_name)
#     get("/my/email", UserController, :get_update_email)
#     put("/my/email", UserController, :do_update_email)
#     get("/my/org-info", UserController, :get_update_org_info)
#     put("/my/org-info", UserController, :do_update_org_info)
#     get("/my/password", UserController, :get_update_password)
#     put("/my/password", UserController, :do_update_password)
#   end
#
#   scope "/admin", PlenarioWeb do
#     pipe_through([:browser, :authenticate, :ensure_authenticated, :ensure_admin])
#
#     get("/", AdminController, :index)
#
#     get("/users", AdminController, :user_index)
#     put("/users/:user_id/activate", AdminController, :activate_user)
#     put("/users/:user_id/archive", AdminController, :archive_user)
#     put("/users/:user_id/trust", AdminController, :trust_user)
#     put("/users/:user_id/untrust", AdminController, :untrust_user)
#     put("/users/:user_id/promote-admin", AdminController, :promote_to_admin)
#     put("/users/:user_id/strip-admin", AdminController, :strip_admin_privs)
#
#     get("/metas", AdminController, :meta_index)
#     get("/metas/:id/approval-review", AdminController, :get_meta_approval_review)
#     post("/metas/:id/approve", AdminController, :approve_meta)
#     post("/metas/:id/disapprove", AdminController, :disapprove_meta)
#   end
#
#   # Other scopes may use custom stacks.
#   # scope "/api", PlenarioWeb do
#   #   pipe_through :api
#   # end
# end
