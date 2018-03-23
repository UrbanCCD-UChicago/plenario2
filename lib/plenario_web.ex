defmodule PlenarioWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PlenarioWeb, :controller
      use PlenarioWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def web_controller do
    quote do
      use Phoenix.Controller, namespace: PlenarioWeb.Web
      import Plug.Conn
      import PlenarioWeb.Router.Helpers
      import PlenarioWeb.Gettext
      import Canary.Plugs

      def do_404(conn) do
        conn
        |> put_status(:not_found)
        |> put_view(PlenarioWeb.ErrorView)
        |> render("404.html")
      end
    end
  end

  def admin_controller do
    quote do
      use Phoenix.Controller, namespace: PlenarioWeb.Admin
      import Plug.Conn
      import PlenarioWeb.Router.Helpers
      import PlenarioWeb.Gettext
      import Canary.Plugs
    end
  end

  def api_controller do
    quote do
      use Phoenix.Controller, namespece: PlenarioWeb.Api
      import Plug.Conn
      import Canary.Plugs
    end
  end

  def web_view do
    quote do
      use Phoenix.View,
        root: "lib/plenario_web/templates/web",
        namespace: PlenarioWeb.Web

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PlenarioWeb.Router.Helpers
      import PlenarioWeb.ErrorHelpers
      import PlenarioWeb.Gettext
      import PlenarioWeb.TemplateHelpers
    end
  end

  def admin_view do
    quote do
      use Phoenix.View,
        root: "lib/plenario_web/templates/admin",
        namespace: PlenarioWeb.Admin

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PlenarioWeb.Router.Helpers
      import PlenarioWeb.ErrorHelpers
      import PlenarioWeb.Gettext
    end
  end

  def shared_view do
    quote do
      use Phoenix.View,
        root: "lib/plenario_web/templates",
        namespace: PlenarioWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PlenarioWeb.Router.Helpers
      import PlenarioWeb.ErrorHelpers
      import PlenarioWeb.Gettext
    end
  end

  def api_view do
    quote do
      use Phoenix.View,
        namespace: PlenarioWeb.Api
      import Phoenix.Controller, only: [view_module: 1]
      import PlenarioWeb.Router.Helpers
      import PlenarioWeb.ErrorHelpers
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
