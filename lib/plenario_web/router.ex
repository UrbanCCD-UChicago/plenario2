defmodule PlenarioWeb.Router do
  use PlenarioWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :maybe_auth do
    plug PlenarioWeb.AuthPipeline
    plug PlenarioWeb.CurrentUserPlug
  end

  pipeline :ensure_auth do
    plug PlenarioWeb.AuthPipeline
    plug Guardian.Plug.EnsureAuthenticated
    plug PlenarioWeb.CurrentUserPlug
  end

  pipeline :admin do
    plug PlenarioWeb.AuthPipeline
    plug Guardian.Plug.EnsureAuthenticated
    plug PlenarioWeb.EnsureAdminPlug
    plug PlenarioWeb.CurrentUserPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PlenarioWeb do
    pipe_through ~w|browser ensure_auth|a

    # me controller
    get "/me",        MeController, :show
    get "/me/edit",   MeController, :edit
    put "/me/update", MeController, :update

    # data sets
    resources "/data-sets", DataSetController, only: ~w|new create edit update delete|a
    post "/data-sets/:id/submit-for-approval", DataSetController, :submit_for_approval
    post "/data-sets/:id/reload-fields", DataSetController, :reload_fields
    post "/data-sets/:id/ingest-now", DataSetController, :ingest_now

    # data set nested resources: fields, virtual dates and virtual points
    resources "/data-sets", DataSetController do
      # fields
      resources "/fields", FieldController, only: ~w|edit update delete|a
      # virtual dates
      resources "/virtual-dates", VirtualDateController, only: ~w|new create edit update delete|a
      # virtual points
      resources "/virtual-points", VirtualPointController, only: ~w|new create edit update delete|a
    end
  end

  scope "/", PlenarioWeb do
    pipe_through ~w|browser maybe_auth|a

    # flat page
    get "/", PageController, :index
    get "/explorer", PageController, :explorer

    # sessions
    get   "/login",     SessionController, :login
    post  "/login",     SessionController, :login
    get   "/register",  SessionController, :register
    post  "/register",  SessionController, :register
    post  "/logout",    SessionController, :logout

    # data sets
    get "/data-sets/:id", DataSetController, :show
  end

  scope "/admin", PlenarioWeb do
    pipe_through ~w|browser admin|a

    get "/", PageAdminController, :index

    resources "/users", UserAdminController

    get "/data-sets",               DataSetAdminController, :index
    get "/data-sets/:id/review",    DataSetAdminController, :review
    post "/data-sets/:id/approve",  DataSetAdminController, :approve
    post "/data-sets/:id/reject",   DataSetAdminController, :reject
  end

  scope "/api/v2", PlenarioWeb do
    pipe_through [:api]

    get "/data-sets", DataSetApiController, :list
    get "/data-sets/:slug", DataSetApiController, :detail
    get "/data-sets/:slug/@aggregate", DataSetApiController, :aggregate
  end
end
