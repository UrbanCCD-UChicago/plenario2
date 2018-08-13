defmodule PlenarioWeb.Router do
  use PlenarioWeb, :router

  use Plug.ErrorHandler

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

  pipeline :maybe_authenticated do
    plug(PlenarioAuth.AuthenticationPipeline)
    plug(PlenarioAuth.CurrentUserPlug)
  end

  pipeline :ensure_authenticated do
    plug(PlenarioAuth.AuthenticationPipeline)
    plug(Guardian.Plug.EnsureAuthenticated)
    plug(PlenarioAuth.CurrentUserPlug)
  end

  pipeline :ensure_admin do
    plug(PlenarioAuth.AuthenticationPipeline)
    plug(Guardian.Plug.EnsureAuthenticated)
    plug(PlenarioAuth.CurrentUserPlug)
    plug(PlenarioAuth.AdminPlug)
  end

  ##
  # public web paths
  scope "/", PlenarioWeb.Web do
    pipe_through([:browser, :maybe_authenticated])

    # landing pages
    get("/", PageController, :index)
    get("/explore", PageController, :explorer)
    get("/explore/array-of-things", PageController, :aot_explorer)

    # auth pages
    get("/login", AuthController, :index)
    post("/login", AuthController, :login)
    post("/register", AuthController, :register)
    post("/logout", AuthController, :logout)

    resources("/data-sets", DataSetController)
    post("/data-sets/:id/submit-for-approval", DataSetController, :submit_for_approval)
    post("/data-sets/:id/ingest-now", DataSetController, :ingest_now)
    get("/data-sets/:id/request-changes", DataSetController, :request_changes)

    post(
      "/data-sets/:id/send-change-request-email",
      DataSetController,
      :send_change_request_email
    )

    post("/data-sets/:meta_id/export", ExportController, :export_meta)

    resources("/data-sets/:dsid/fields", DataSetFieldController)
    resources("/data-sets/:dsid/virtual-dates", VirtualDateController)
    resources("/data-sets/:dsid/virtual-points", VirtualPointController)
    resources("/data-sets/:meta_id/charts", ChartController)
    get("/data-sets/:meta_id/charts/:id/render", ChartController, :render_chart)

    resources(
      "/data-sets/:meta_id/charts/:chart_id/datasets",
      ChartDatasetController,
      only: [
        :new,
        :create,
        :edit,
        :update,
        :delete
      ]
    )

    post("/notes/:id/acknowledge", AdminUserNoteController, :mark_acknowledged)
  end

  scope "/", PlenarioWeb.Web do
    pipe_through([:browser, :ensure_authenticated])

    get("/me", MeController, :index)
    get("/me/edit", MeController, :edit)
    put("/me/update", MeController, :update)
    get("/me/change-password", MeController, :edit_password)
    put("/me/change-password", MeController, :update_password)
  end

  ##
  # admin paths
  scope "/admin", PlenarioWeb.Admin do
    pipe_through([:browser, :ensure_admin])

    get("/", AdminPageController, :index)

    resources("/users", UserController)
    post("/users/:id/promote-to-admin", UserController, :promote_to_admin)
    post("/users/:id/strip-admin-privs", UserController, :strip_admin_privs)
    post("/users/:id/activate", UserController, :activate)
    post("/users/:id/archive", UserController, :archive)

    resources("/metas", MetaController)
    get("/metas/:id/review", MetaController, :review)
    post("/metas/:id/approve", MetaController, :approve)
    post("/metas/:id/disapprove", MetaController, :disapprove)

    resources("/etl-jobs", EtlJobController)

    resources("/export-jobs", ExportJobController)

    resources("/aot", AotController)
  end

  ##
  # api paths
  scope "/api/v2", PlenarioWeb.Api do
    pipe_through([:api])

    get("/data-sets", ListController, :get)
    get("/data-sets/@head", ListController, :head)

    get("/data-sets/:slug", DetailController, :get)
    get("/data-sets/:slug/@head", DetailController, :head)
    get("/data-sets/:slug/@describe", DetailController, :describe)

    get("/aot", AotController, :get)
    get("/aot/@head", AotController, :head)
    get("/aot/@describe", AotController, :describe)

    # Method not allowed
    [&post/3, &put/3, &patch/3, &delete/3, &connect/3, &trace/3]
    |> Enum.each(fn verb -> verb.("/*path", MethodNotAllowedController, :match) end)
  end

  scope "/v1/api", PlenarioWeb.Api do
    pipe_through([:api])

    get("/datasets", ShimController, :datasets)
    get("/fields/:slug", ShimController, :fields)
    get("/detail", ShimController, :detail)

    # Method not allowed
    [&post/3, &put/3, &patch/3, &delete/3, &connect/3, &trace/3]
    |> Enum.each(fn verb -> verb.("/*path", MethodNotAllowedController, :match) end)
  end

  if Mix.env() == :dev do
    forward("/sent-emails", Bamboo.EmailPreviewPlug)
  end
end
